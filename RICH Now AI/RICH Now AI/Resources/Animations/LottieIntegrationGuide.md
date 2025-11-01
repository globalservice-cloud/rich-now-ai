# Lottie 動畫整合指南

## 問題描述
如果您想要使用 Lottie 動畫來替代 SwiftUI 原生動畫，需要添加 Lottie 依賴。

## 解決方案

### 方法 1: 使用 Swift Package Manager (推薦)

1. 在 Xcode 中打開專案
2. 選擇 `File` > `Add Package Dependencies...`
3. 輸入 Lottie 的 URL: `https://github.com/airbnb/lottie-ios`
4. 選擇最新版本並點擊 `Add Package`
5. 在需要使用的文件中添加 `import Lottie`

### 方法 2: 使用 CocoaPods

1. 在專案根目錄創建 `Podfile`：
```ruby
platform :ios, '15.0'
use_frameworks!

target 'RICH Now AI' do
  pod 'lottie-ios'
end
```

2. 執行 `pod install`
3. 使用 `.xcworkspace` 文件打開專案

### 方法 3: 使用 Carthage

1. 在 `Cartfile` 中添加：
```
github "airbnb/lottie-ios"
```

2. 執行 `carthage update`
3. 將 Lottie.framework 添加到專案中

## 使用 Lottie 的 WelcomeAnimationView

如果您選擇使用 Lottie，可以將 `WelcomeAnimationView.swift` 替換為以下版本：

```swift
import SwiftUI
import Lottie

struct WelcomeAnimationView: View {
    let onAnimationComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var isAnimating = true
    @State private var showSkipButton = false
    
    var body: some View {
        ZStack {
            // 背景漸層
            LinearGradient(
                colors: [Color(hex: "#1E3A8A")!, Color(hex: "#312E81")!],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Lottie 動畫
            LottieView(animation: .named("gabriel_welcome"))
                .playing(loopMode: .playOnce)
                .animationSpeed(1.0)
                .onComplete { completed in
                    if completed {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onAnimationComplete()
                        }
                    }
                }
                .scaleEffect(1.0)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: isAnimating)
            
            // 跳過按鈕
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        onSkip()
                    }) {
                        Text("welcome.animation.skip".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .opacity(showSkipButton ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3).delay(2.0), value: showSkipButton)
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showSkipButton = true
            }
        }
    }
}
```

## 創建 Lottie 動畫文件

1. 使用 After Effects 或其他支援的軟體創建動畫
2. 導出為 JSON 格式
3. 將 JSON 文件添加到專案的 `Resources/Animations/` 目錄
4. 確保文件名為 `gabriel_welcome.json`

## 動畫設計建議

### 8秒動畫序列：
1. **0-1秒**: 星空背景淡入
2. **1-3秒**: 流星從天而降
3. **3-5秒**: 加百列天使出現
4. **5-7秒**: 文字內容顯示
5. **7-8秒**: 淡出效果

### 動畫元素：
- 星空背景
- 流星軌跡
- 加百列天使形象
- 光環效果
- 文字動畫
- 背景音樂（可選）

## 當前解決方案

目前我們使用 SwiftUI 原生動畫來實現迎賓動畫，這避免了外部依賴，並且提供了：

- 星空背景動畫
- 流星效果
- 加百列天使形象
- 漸變文字效果
- 完整的 8 秒動畫序列

這個解決方案不需要額外的依賴，並且提供了良好的性能和用戶體驗。
