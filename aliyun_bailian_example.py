# 阿里云百炼大模型平台 API 调用示例
# API Key: sk-sp-cb9894b2bc934921ad36eb34996f961b
# 
# 阿里云百炼(Model Studio)是大模型服务平台，提供多种模型：
# - 通义千问系列：qwen-max, qwen-plus, qwen-turbo, qwen-coder
# - Qwen3系列：qwen3-max, qwen3-235b-a22b-instruct 等
# - DeepSeek系列：deepseek-v3.1, deepseek-v3.2 等
# 
# 安装依赖：pip install dashscope

import os
from http import HTTPStatus
from dashscope import Generation

API_KEY = "sk-sp-cb9894b2bc934921ad36eb34996f961b"

MODELS = {
    "qwen-max": "通义千问Max - 适合复杂任务，能力最强",
    "qwen-plus": "通义千问Plus - 效果、速度、成本均衡",
    "qwen-turbo": "通义千问Turbo - 适合简单任务，速度快、成本低",
    "qwen-coder": "通义千问Coder - 卓越的代码模型",
    "qwen3-max": "Qwen3 Max - 最新旗舰模型",
    "deepseek-v3.1": "DeepSeek V3.1 - 第三方模型",
}

def call_bailian(model_name: str, prompt: str, system_prompt: str = "You are a helpful assistant."):
    """
    调用阿里云百炼平台模型
    
    Args:
        model_name: 模型名称，如 qwen-max, qwen-plus, qwen-turbo 等
        prompt: 用户输入的提示词
        system_prompt: 系统提示词
    """
    print(f"\n=== 调用模型: {model_name} ===")
    print(f"模型说明: {MODELS.get(model_name, '未知模型')}")
    
    messages = [
        {'role': 'system', 'content': system_prompt},
        {'role': 'user', 'content': prompt}
    ]
    
    try:
        response = Generation.call(
            model=model_name,
            messages=messages,
            result_format='message',
            api_key=API_KEY
        )
        
        if response.status_code == HTTPStatus.OK:
            print("响应结果：")
            print(response.output.choices[0].message.content)
            return response.output.choices[0].message.content
        else:
            print(f"请求失败：")
            print(f"Status Code: {response.status_code}")
            print(f"Error: {response.message}")
            if hasattr(response, 'code'):
                print(f"Error Code: {response.code}")
            return None
    
    except Exception as e:
        print(f"发生异常：{e}")
        return None

def call_with_streaming(model_name: str, prompt: str):
    """流式输出调用"""
    print(f"\n=== 流式调用模型: {model_name} ===")
    
    messages = [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': prompt}
    ]
    
    try:
        responses = Generation.call(
            model=model_name,
            messages=messages,
            result_format='message',
            stream=True,
            incremental_output=True,
            api_key=API_KEY
        )
        
        print("响应结果：")
        full_content = ""
        for response in responses:
            if response.status_code == HTTPStatus.OK:
                content = response.output.choices[0].message.content
                print(content, end='', flush=True)
                full_content += content
            else:
                print(f"\n请求失败：{response.message}")
                return None
        print()
        return full_content
    
    except Exception as e:
        print(f"发生异常：{e}")
        return None

def list_available_models():
    """列出可用的模型"""
    print("=== 阿里云百炼平台可用模型 ===")
    for model, desc in MODELS.items():
        print(f"  {model}: {desc}")
    print()

if __name__ == "__main__":
    print("=" * 50)
    print("阿里云百炼大模型平台 API 调用示例")
    print("=" * 50)
    
    list_available_models()
    
    call_bailian("qwen-plus", "你好，请介绍一下你自己")
    
    call_bailian("qwen-turbo", "用一句话解释什么是人工智能")
    
    call_with_streaming("qwen-plus", "请写一首关于春天的短诗")
    
    print("\n=== 调用完成 ===")
