//
//  GabrielSettingsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI

struct GabrielSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var selectedGender: GabrielGender = .male
    @State private var selectedOutfit: GabrielOutfit = .classic
    @State private var selectedPersonality: GabrielPersonality = .wise
    @State private var selectedMood: GabrielMood = .friendly
    @State private var showingPreview = false
    
    var body: some View {
        NavigationView {
            Form {
                // 性別選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("加百列性別")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            ForEach(GabrielGender.allCases, id: \.self) { gender in
                                GenderCard(
                                    gender: gender,
                                    isSelected: selectedGender == gender
                                ) {
                                    selectedGender = gender
                                }
                            }
                        }
                        
                        Text("選擇加百列的性別表現")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("基本設定")
                }
                
                // 服裝選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("服裝風格")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(GabrielOutfit.allCases, id: \.self) { outfit in
                                OutfitCard(
                                    outfit: outfit,
                                    isSelected: selectedOutfit == outfit
                                ) {
                                    selectedOutfit = outfit
                                }
                            }
                        }
                        
                        Text("選擇加百列的服裝風格")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("外觀設定")
                }
                
                // 個性選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("個性特質")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(GabrielPersonality.allCases, id: \.self) { personality in
                            PersonalityRow(
                                personality: personality,
                                isSelected: selectedPersonality == personality
                            ) {
                                selectedPersonality = personality
                            }
                        }
                        
                        Text("選擇加百列的個性表現")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("個性設定")
                }
                
                // 心情選擇
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("對話心情")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(GabrielMood.allCases, id: \.self) { mood in
                            MoodRow(
                                mood: mood,
                                isSelected: selectedMood == mood
                            ) {
                                selectedMood = mood
                            }
                        }
                        
                        Text("選擇加百列的對話風格")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("對話設定")
                }
                
                // 預覽設定
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("設定預覽")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        GabrielPreviewCard(
                            gender: selectedGender,
                            outfit: selectedOutfit,
                            personality: selectedPersonality,
                            mood: selectedMood
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
            .navigationTitle("加百列設定")
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
                GabrielPreviewView(
                    gender: selectedGender,
                    outfit: selectedOutfit,
                    personality: selectedPersonality,
                    mood: selectedMood
                )
            }
        }
    }
    
    // MARK: - 輔助方法
    
    private func loadCurrentSettings() {
        if let settings = settingsManager.currentSettings {
            selectedGender = GabrielGender(rawValue: settings.gabrielGender) ?? .male
            selectedOutfit = GabrielOutfit(rawValue: settings.gabrielOutfit) ?? .classic
            selectedPersonality = GabrielPersonality(rawValue: settings.gabrielPersonality) ?? .wise
            selectedMood = GabrielMood(rawValue: settings.gabrielMood) ?? .friendly
        }
    }
    
    private func saveSettings() {
        settingsManager.updateGabrielGender(selectedGender)
        settingsManager.updateGabrielOutfit(selectedOutfit)
        settingsManager.updateGabrielPersonality(selectedPersonality)
        settingsManager.updateGabrielMood(selectedMood)
        dismiss()
    }
}

// MARK: - 性別卡片

struct GenderCard: View {
    let gender: GabrielGender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: gender == .male ? "person.fill" : gender == .female ? "person.fill" : "person.2.fill")
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(gender.displayName)
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

// MARK: - 服裝卡片

struct OutfitCard: View {
    let outfit: GabrielOutfit
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: outfit.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .orange)
                
                Text(outfit.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.orange : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 個性行

struct PersonalityRow: View {
    let personality: GabrielPersonality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                
                Text(personality.displayName)
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

// MARK: - 心情行

struct MoodRow: View {
    let mood: GabrielMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.yellow)
                
                Text(mood.displayName)
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

// MARK: - 加百列預覽卡片

struct GabrielPreviewCard: View {
    let gender: GabrielGender
    let outfit: GabrielOutfit
    let personality: GabrielPersonality
    let mood: GabrielMood
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("加百列")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(gender.displayName) • \(outfit.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("歡迎！我是您的財務守護天使。")
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            HStack {
                Text("個性：\(personality.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("心情：\(mood.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 完整預覽視圖

struct GabrielPreviewView: View {
    @Environment(\.dismiss) var dismiss
    let gender: GabrielGender
    let outfit: GabrielOutfit
    let personality: GabrielPersonality
    let mood: GabrielMood
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("加百列預覽")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                // 模擬對話介面
                VStack(spacing: 16) {
                    // 加百列頭像
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("加百列")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(gender.displayName) • \(outfit.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 模擬對話氣泡
                    VStack(alignment: .leading, spacing: 8) {
                        Text("歡迎！我是您的財務守護天使。")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        Text("今天有什麼財務問題需要協助嗎？")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                Spacer()
            }
            .padding()
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
    GabrielSettingsView()
}
