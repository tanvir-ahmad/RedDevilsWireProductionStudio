import os
import argparse
import asyncio
import json
import requests
from dotenv import load_dotenv
import google.generativeai as genai
import edge_tts
from duckduckgo_search import DDGS
from moviepy import ImageClip, AudioFileClip, concatenate_videoclips, CompositeVideoClip
import time
import subprocess
import imageio_ffmpeg
import sys
import io
import re

# Force UTF-8 for Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Load environment variables
load_dotenv()

# Get ffmpeg path from imageio_ffmpeg
try:
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
except Exception as e:
    print(f"Warning: Could not locate ffmpeg: {e}")
    ffmpeg_exe = "ffmpeg" # Fallback to system path

def get_gemini_response(prompt, api_key, model_name="gemini-flash-latest", temperature=1.0):
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel(model_name)
    generation_config = genai.types.GenerationConfig(temperature=temperature)
    response = model.generate_content(prompt, generation_config=generation_config)
    return response.text

def get_groq_response(prompt, api_key, model_name="llama-3.3-70b-versatile", temperature=1.0):
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model_name,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": temperature
    }
    response = requests.post(url, headers=headers, json=payload)
    if response.status_code == 200:
        return response.json()["choices"][0]["message"]["content"]
    else:
        raise Exception(f"Groq API Error {response.status_code}: {response.text}")

async def generate_voiceover(script, output_path, voice="en-GB-RyanNeural", rate="+0%"):
    print(f"Generating voiceover: {output_path} using voice {voice}")
    communicate = edge_tts.Communicate(script, voice, rate=rate, pitch="+5Hz")
    await communicate.save(output_path)

def generate_script(raw_news, channel_name, intro_hook, outro_hook, provider="gemini", api_key=None):
    """Generates a standalone YouTube script with dynamic branding."""
    print(f"Generating script for {channel_name} using {provider}...")
    prompt = (
        f"You are the lead presenter for {channel_name}, a high-energy professional sports fan and anchor. "
        f"Based on this news: {raw_news}, write a verbatim VOICEOVER NARRATIVE.\n\n"
        "REQUIREMENTS:\n"
        f"- START with exactly this hook: '{intro_hook}'\n"
        f"- END with exactly this hook: '{outro_hook}'\n"
        "- REPHRASE AND EXPAND every point into exciting commentary. Do not summarize.\n"
        "- Write in the FIRST PERSON as a presenter.\n"
        "- Continuous narrative flow ONLY. No stage directions.\n"
        "Only provide the spoken script."
    )
    if provider == "gemini":
        return get_gemini_response(prompt, api_key)
    return get_groq_response(prompt, api_key)

def generate_metadata(script, channel_name, provider="gemini", api_key=None):
    """Generates SEO metadata focused on the specific channel branding."""
    print(f"Generating SEO metadata for {channel_name}...")
    prompt = (
        f"Based on this YouTube script for the channel '{channel_name}': {script}, suggest 3 catchy titles, a SEO description, 10 keywords, and 10 hashtags. "
        "RETURN AS A CLEAN JSON OBJECT WITH KEYS: titles (list), description (string), keywords (list), hashtags (list). "
        "IMPORTANT: NO trailing commas. Escape newlines as \\n. No conversational filler."
    )
    if provider == "gemini":
        text = get_gemini_response(prompt, api_key)
    else:
        text = get_groq_response(prompt, api_key)
    
    data = _robust_json_parse(text)
    if "seo" in data: return data["seo"]
    return data

def generate_production_package(raw_news, channel_name, intro_hook, outro_hook, provider="gemini", api_key=None):
    """Generates script and metadata using localized branding context."""
    script = generate_script(raw_news, channel_name, intro_hook, outro_hook, provider, api_key)
    seo = generate_metadata(script, channel_name, provider, api_key)
    return {"script": script, "seo": seo}

def _robust_json_parse(text):
    """Multi-stage recovery parser for AI generated JSON."""
    text = text.strip()
    if "```json" in text:
        text = text.split("```json")[-1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[-1].split("```")[0].strip()
    
    def try_parse(t):
        start = t.find('{')
        end = t.rfind('}')
        if start != -1 and end != -1:
            snippet = t[start:end+1]
            return json.loads(snippet)
        return None

    # Stage 1: Fast parse
    try:
        res = try_parse(text)
        if res: return res
    except: pass

    # Stage 2: Clean trailing commas
    try:
        clean_text = re.sub(r',\s*([\]}])', r'\1', text)
        res = try_parse(clean_text)
        if res: return res
    except: pass

    # Stage 3: Regex recovery
    print("Warning: JSON parsing failed. Falling back to pattern-based extraction.")
    def get_val(key, default="", is_list=False):
        if is_list:
            match = re.search(f'"{key}"\s*:?\s*\[(.*?)\]', text, re.DOTALL)
            if match:
                return [s.strip().strip('"') for s in re.findall(r'"(.*?)"', match.group(1))]
        else:
            match = re.search(f'"{key}"\s*:?\s*"(.*?)"(?=,\s*"\w+"|\s*}})', text, re.DOTALL)
            if match:
                return match.group(1).replace('\\n', '\n').replace('\\"', '"')
        return default

    return {
        "script": get_val("script", "Error parsing response."),
        "seo": {
            "titles": get_val("titles", [], True),
            "description": get_val("description", f"RECOVERY MODE: JSON syntax error detected.\n{text}"),
            "keywords": get_val("keywords", [], True),
            "hashtags": get_val("hashtags", [], True)
        }
    }

def remove_silence(audio_path):
    temp_path = "temp_refined.mp3"
    try:
        cmd = [ffmpeg_exe, "-y", "-i", audio_path, "-af", "silenceremove=stop_periods=-1:stop_duration=0.2:stop_threshold=-40dB", temp_path]
        subprocess.run(cmd, check=True, capture_output=True)
        if os.path.exists(temp_path): os.replace(temp_path, audio_path)
    except: pass

def fetch_images(keywords, count=5, output_dir="assets"):
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    image_paths = []
    try:
        with DDGS() as ddgs:
            results = ddgs.images(keywords, max_results=count)
            for i, res in enumerate(results):
                try:
                    response = requests.get(res['image'], timeout=10)
                    if response.status_code == 200:
                        path = os.path.join(output_dir, f"img_{i}.jpg")
                        with open(path, 'wb') as f: f.write(response.content)
                        image_paths.append(path)
                    if len(image_paths) >= count: break
                except: continue
    except: pass
    return image_paths

def create_video(audio_path, image_paths, output_path):
    audio = AudioFileClip(audio_path)
    img_duration = audio.duration / len(image_paths)
    clips = []
    for img_path in image_paths:
        try:
            clip = ImageClip(img_path).with_duration(img_duration).with_fps(24)
            clip = clip.resized(width=1920) if clip.w / clip.h > 1.77 else clip.resized(height=1080)
            clips.append(clip.with_position('center'))
        except: continue
    final_video = concatenate_videoclips(clips, method="compose").with_audio(audio)
    final_video.write_videofile(output_path, codec="libx264", audio_codec="aac", fps=24)

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text", type=str)
    parser.add_argument("--file", type=str, help="Path to text file containing raw news")
    parser.add_argument("--metadata-only", action="store_true")
    parser.add_argument("--only-audio", action="store_true")
    parser.add_argument("--script", type=str)
    parser.add_argument("--rate", type=str, default="+0%")
    parser.add_argument("--provider", type=str, default="gemini")
    parser.add_argument("--api-key", type=str)
    # Channel Branding Params
    parser.add_argument("--channel-name", type=str, default="RedDevilsWire")
    parser.add_argument("--subject", type=str, default="Manchester United players")
    parser.add_argument("--intro-hook", type=str, default="Welcome back to RedDevilsWire!")
    parser.add_argument("--outro-hook", type=str, default="Subscribe for more updates!")
    parser.add_argument("--voice", type=str, default="en-GB-RyanNeural")
    
    args = parser.parse_args()

    # Load raw news from file if provided
    raw_news = args.text
    if args.file and os.path.exists(args.file):
        with open(args.file, 'r', encoding='utf-8') as f:
            raw_news = f.read()

    if not raw_news and not args.script:
        print("Error: Either --text or --file must be provided.")
        exit(1)

    key = args.api_key or (os.getenv("GOOGLE_API_KEY") if args.provider == "gemini" else os.getenv("GROQ_API_KEY"))
    if not key: exit(1)

    if args.metadata_only:
        package = generate_production_package(raw_news, args.channel_name, args.intro_hook, args.outro_hook, args.provider, key) if not args.script else {"script": args.script, "seo": generate_metadata(args.script, args.channel_name, args.provider, key)}
        print("---METADATA_START---")
        print(json.dumps(package))
        print("---METADATA_END---")
        return

    script = args.script or generate_script(raw_news, args.channel_name, args.intro_hook, args.outro_hook, args.provider, key)
    audio_file = "audio.mp3"
    
    if args.only_audio:
        print(f"Generating voiceover using {args.voice}...")
        await generate_voiceover(script, audio_file, voice=args.voice, rate=args.rate)
        remove_silence(audio_file)
        return

    await generate_voiceover(script, audio_file, voice=args.voice, rate=args.rate)
    remove_silence(audio_file)
    images = fetch_images(args.subject, count=5)
    if images: create_video(audio_file, images, "final_video.mp4")

if __name__ == "__main__":
    asyncio.run(main())
