//
//  AppearanceSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedDesignStyle: DesignStyle = .modern
    @State private var selectedColorScheme: ColorScheme = .system
    @State private var selectedFontSize: FontSize = .medium
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            Form {
                // 設計風格選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("設計風格")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(DesignStyle.allCases, id: \.self) { style in
                                DesignStyleCard(
                                    style: style,
                                    isSelected: selectedDesignStyle == style
                                ) {
                                    selectedDesignStyle = style
                                }
                            }
                        }
                        
                        Text("選擇您喜歡的應用程式設計風格")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("視覺風格")
                }
                
                // 顏色方案選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("顏色方案")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(ColorScheme.allCases, id: \.self) { scheme in
                            ColorSchemeRow(
                                scheme: scheme,
                                isSelected: selectedColorScheme == scheme
                            ) {
                                selectedColorScheme = scheme
                            }
                        }
                        
                        Text("選擇應用程式的顏色主題")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("顏色主題")
                }
                
                // 字體大小選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("字體大小")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(FontSize.allCases, id: \.self) { size in
                            FontSizeRow(
                                size: size,
                                isSelected: selectedFontSize == size
                            ) {
                                selectedFontSize = size
                            }
                        }
                        
                        Text("調整應用程式文字的大小")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("文字設定")
                }
                
                // 預覽設定
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("設定預覽")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        PreviewCard(
                            designStyle: selectedDesignStyle,
                            colorScheme: selectedColorScheme,
                            fontSize: selectedFontSize
                        )
                        
                        Button("查看完整預覽") {
                            showingPreview = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("預覽")
                }
            }
            .navigationTitle("外觀設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveSettings()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
            }
            .fullScreenCover(isPresented: $showingPreview) {
                AppearancePreviewView(
                    designStyle: selectedDesignStyle,
                    colorScheme: selectedColorScheme,
                    fontSize: selectedFontSize
                )
            }
        }
    }
    
    // MARK: - 輔助方法
    
    private func loadCurrentSettings() {
        if let settings = settingsManager.currentSettings {
            selectedDesignStyle = DesignStyle(rawValue: settings.designStyle) ?? .modern
            selectedColorScheme = ColorScheme(rawValue: settings.colorScheme) ?? .system
            selectedFontSize = FontSize(rawValue: settings.fontSize) ?? .medium
        }
    }
    
    private func saveSettings() {
        settingsManager.updateDesignStyle(selectedDesignStyle)
        settingsManager.updateColorScheme(selectedColorScheme)
        settingsManager.updateFontSize(selectedFontSize)
        dismiss()
    }
}

// MARK: - 設計風格卡片

struct DesignStyleCard: View {
    let style: DesignStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: style.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 顏色方案行

struct ColorSchemeRow: View {
    let scheme: ColorScheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(scheme == .light ? Color.white : scheme == .dark ? Color.black : Color.blue)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.primary, lineWidth: 1)
                    )
                
                Text(scheme.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 字體大小行

struct FontSizeRow: View {
    let size: FontSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Aa")
                    .font(.system(size: 16 * size.scaleFactor))
                    .foregroundColor(.primary)
                
                Text(size.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 預覽卡片

struct PreviewCard: View {
    let designStyle: DesignStyle
    let colorScheme: ColorScheme
    let fontSize: FontSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("加百列")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("您的財務守護天使")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("歡迎回來！今天有什麼財務問題需要協助嗎？")
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 完整預覽視圖

struct AppearancePreviewView: View {
    @Environment(\.dismiss) var dismiss
    let designStyle: DesignStyle
    let colorScheme: ColorScheme
    let fontSize: FontSize
    
    var body: some View {
        NavigationView {
            VStack {
                Text("外觀預覽")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                // 模擬應用程式介面
                VStack(spacing: 20) {
                    // 模擬標題列
                    HStack {
                        Text("RICH Now AI")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 模擬內容區域
                    VStack(spacing: 16) {
                        Text("設計風格：\(designStyle.displayName)")
                            .font(.headline)
                        
                        Text("顏色方案：\(colorScheme.displayName)")
                            .font(.subheadline)
                        
                        Text("字體大小：\(fontSize.displayName)")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 預覽

#Preview {
    AppearanceSettingsView()
}
