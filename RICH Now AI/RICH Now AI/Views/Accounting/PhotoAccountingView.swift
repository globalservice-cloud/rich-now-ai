//
//  PhotoAccountingView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct PhotoAccountingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var photoManager = PhotoAccountingManager.shared
    @StateObject private var transactionParser = TransactionParser()
    
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingExtractionResult = false
    @State private var showingReceiptConfirmation = false
    @State private var showingTransactionPreview = false
    @State private var parsedTransaction: ParsedTransaction?
    @State private var isProcessing = false
    @State private var extractionHistory: [ExtractedReceiptData] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 標題
                VStack(spacing: 8) {
                    Text(LocalizationManager.shared.localizedString("photo_accounting.title"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(LocalizationManager.shared.localizedString("photo_accounting.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 主要操作區域
                if let image = selectedImage {
                    ImagePreviewSection(
                        image: image,
                        onRetake: retakePhoto,
                        onProcess: processImage
                    )
                } else {
                    PhotoSelectionSection(
                        onSelectFromLibrary: { showingImagePicker = true },
                        onTakePhoto: { showingCamera = true }
                    )
                }
                
                // 處理狀態
                if isProcessing {
                    ProcessingStatusView()
                }
                
                // 錯誤訊息
                if let error = photoManager.processingError {
                    ErrorMessageView(message: error)
                }
                
                // 提取結果
                if let extractedData = photoManager.extractedData {
                    ExtractionResultView(
                        data: extractedData,
                        onEdit: {
                            showingReceiptConfirmation = true
                        },
                        onProcess: {
                            showingReceiptConfirmation = true
                        }
                    )
                }
                
                Spacer()
                
                // 歷史記錄
                if !extractionHistory.isEmpty {
                    ExtractionHistorySection(history: extractionHistory)
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle(LocalizationManager.shared.localizedString("photo_accounting.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { imageData in
                    handleImageSelection(imageData)
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(
                    capturedImage: $selectedImage,
                    isPresented: $showingCamera,
                    onImageCaptured: { image in
                        selectedImage = image
                        photoManager.extractedData = nil
                        photoManager.processingError = nil
                        showingExtractionResult = false
                        showingTransactionPreview = false
                        parsedTransaction = nil
                    }
                )
            }
            .sheet(isPresented: $showingReceiptConfirmation) {
                if let extractedData = photoManager.extractedData {
                    ReceiptConfirmationView(
                        data: extractedData,
                        onConfirm: { confirmedData in
                            processConfirmedReceipt(confirmedData)
                            showingReceiptConfirmation = false
                        },
                        onCancel: {
                            showingReceiptConfirmation = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingTransactionPreview) {
                if let transaction = parsedTransaction {
                    TransactionPreviewView(transaction: transaction) { confirmedTransaction in
                        saveTransaction(confirmedTransaction)
                    }
                }
            }
            .onAppear {
                loadExtractionHistory()
            }
        }
    }
    
    // MARK: - 圖片處理
    
    private func handleImageSelection(_ imageData: Data) {
        guard let image = UIImage(data: imageData) else {
            photoManager.processingError = LocalizationManager.shared.localizedString("photo_accounting.error.invalid_image")
            return
        }

        selectedImage = image
        photoManager.extractedData = nil
        photoManager.processingError = nil
        showingImagePicker = false
        showingCamera = false
        showingExtractionResult = false
        showingTransactionPreview = false
        parsedTransaction = nil
    }

    private func processImage() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        
        // 判斷圖片來源：如果是從相機拍攝的，使用 .camera，否則使用 .photoLibrary
        let source: PhotoAccountingManager.ImageSource = showingCamera ? .camera : .photoLibrary
        
        Task {
            do {
                let extractedData = try await photoManager.processReceiptImage(image, source: source)
                await MainActor.run {
                    photoManager.saveExtractionHistory(extractedData)
                    loadExtractionHistory()
                    isProcessing = false
                    // 自動顯示確認介面
                    showingReceiptConfirmation = true
                }
            } catch {
                await MainActor.run {
                    photoManager.processingError = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
    
    private func retakePhoto() {
        selectedImage = nil
        photoManager.extractedData = nil
        photoManager.processingError = nil
    }
    
    // MARK: - 提取結果處理
    
    private func processConfirmedReceipt(_ confirmedData: ExtractedReceiptData) {
        // 更新 photoManager 的 extractedData
        photoManager.extractedData = confirmedData
        
        // 將確認後的收據數據轉換為交易
        isProcessing = true
        
        Task {
            do {
                // 將提取的數據轉換為交易格式
                let transactionText = buildTransactionText(from: confirmedData)
                let parsedTransaction = try await transactionParser.parseTransaction(from: transactionText)
                
                await MainActor.run {
                    self.parsedTransaction = parsedTransaction
                    self.isProcessing = false
                    self.showingTransactionPreview = true
                }
            } catch {
                await MainActor.run {
                    photoManager.processingError = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func buildTransactionText(from data: ExtractedReceiptData) -> String {
        return """
        Merchant: \(data.merchant)
        Amount: \(data.amount) \(data.currency)
        Date: \(data.date)
        Category: \(data.category)
        Payment Method: \(data.paymentMethod)
        Items: \(data.items.map { "\($0.name) x\($0.quantity) $\($0.price)" }.joined(separator: ", "))
        Tax: \(data.tax)
        Total: \(data.total)
        """
    }
    
    // MARK: - 交易保存
    
    private func saveTransaction(_ transaction: ParsedTransaction) {
        // 保存交易到 SwiftData
        let transactionType: TransactionType = transaction.type == .income ? .income : .expense
        let category = mapCategoryToTransactionCategory(transaction.category)
        
        let newTransaction = Transaction(
            amount: transaction.amount,
            type: transactionType,
            category: category,
            description: transaction.description,
            inputMethod: "image",
            originalText: nil
        )
        
        // 設定 AI 分析結果
        newTransaction.isAutoCategorized = true
        newTransaction.aiConfidence = photoManager.extractedData?.confidence
        newTransaction.aiSuggestion = transaction.category
        
        // 如果有商家名稱，添加到 merchantName
        if let merchant = photoManager.extractedData?.merchant {
            newTransaction.merchantName = merchant
        }
        
        // 保存到資料庫
        let context = modelContext
        context.insert(newTransaction)
        
        do {
            try context.save()
            // 清除提取的數據
            photoManager.extractedData = nil
            selectedImage = nil
            showingTransactionPreview = false
            parsedTransaction = nil
        } catch {
            photoManager.processingError = "保存失敗：\(error.localizedDescription)"
        }
    }
    
    private func mapCategoryToTransactionCategory(_ category: String) -> TransactionCategory {
        switch category {
        case "餐飲": return .food
        case "交通": return .transport
        case "居住": return .housing
        case "娛樂": return .entertainment
        case "教育": return .education
        case "醫療": return .healthcare
        case "購物": return .shopping
        default: return .other_expense
        }
    }
    
    // MARK: - 歷史記錄
    
    private func loadExtractionHistory() {
        extractionHistory = photoManager.getExtractionHistory()
    }
}

// MARK: - 照片選擇區域

struct PhotoSelectionSection: View {
    let onSelectFromLibrary: () -> Void
    let onTakePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 說明文字
            VStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(LocalizationManager.shared.localizedString("photo_accounting.instructions.title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString("photo_accounting.instructions.description"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 操作按鈕
            VStack(spacing: 12) {
                Button(action: onTakePhoto) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.take_photo"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                }
                
                Button(action: onSelectFromLibrary) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.select_from_library"))
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - 圖片預覽區域

struct ImagePreviewSection: View {
    let image: UIImage
    let onRetake: () -> Void
    let onProcess: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 圖片預覽
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // 圖片資訊
            ImageInfoView(image: image)
            
            // 操作按鈕
            HStack(spacing: 12) {
                Button(action: onRetake) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.retake"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                Button(action: onProcess) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.process"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 圖片資訊視圖

struct ImageInfoView: View {
    let image: UIImage
    
    var body: some View {
        let imageInfo = image.getImageInfo()
        
        VStack(spacing: 8) {
            HStack {
                Text(LocalizationManager.shared.localizedString("photo_accounting.image_info.size"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(imageInfo.size.width)) × \(Int(imageInfo.size.height))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text(LocalizationManager.shared.localizedString("photo_accounting.image_info.format"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(imageInfo.format == .jpeg ? "JPEG" : "PNG")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text(LocalizationManager.shared.localizedString("photo_accounting.image_info.ocr_suitable"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Image(systemName: imageInfo.isSuitableForOCR ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(imageInfo.isSuitableForOCR ? .green : .orange)
                    Text(imageInfo.isSuitableForOCR ? LocalizationManager.shared.localizedString("common.yes") : LocalizationManager.shared.localizedString("common.no"))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - 提取結果視圖

struct ExtractionResultView: View {
    let data: ExtractedReceiptData
    let onEdit: () -> Void
    let onProcess: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 信心度指示器
            HStack {
                Text(LocalizationManager.shared.localizedString("photo_accounting.confidence"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(data.confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(data.confidence > 0.8 ? .green : data.confidence > 0.6 ? .orange : .red)
            }
            
            // 提取的數據
            VStack(alignment: .leading, spacing: 8) {
                ExtractedDataRow(
                    title: LocalizationManager.shared.localizedString("photo_accounting.merchant"),
                    value: data.merchant
                )
                
                ExtractedDataRow(
                    title: LocalizationManager.shared.localizedString("photo_accounting.amount"),
                    value: "\(data.currency) \(String(format: "%.2f", data.amount))"
                )
                
                ExtractedDataRow(
                    title: LocalizationManager.shared.localizedString("photo_accounting.date"),
                    value: data.date
                )
                
                ExtractedDataRow(
                    title: LocalizationManager.shared.localizedString("photo_accounting.category"),
                    value: data.category
                )
                
                if !data.items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizationManager.shared.localizedString("photo_accounting.items"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(data.items, id: \.name) { item in
                            Text("• \(item.name) x\(item.quantity) - \(data.currency) \(item.price, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            // 操作按鈕
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.edit"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Button(action: onProcess) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text(LocalizationManager.shared.localizedString("photo_accounting.create_transaction"))
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - 提取數據行

struct ExtractedDataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 提取歷史區域

struct ExtractionHistorySection: View {
    let history: [ExtractedReceiptData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizationManager.shared.localizedString("photo_accounting.history"))
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(history.suffix(5), id: \.id) { data in
                        HistoryItemView(data: data)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - 歷史項目視圖

struct HistoryItemView: View {
    let data: ExtractedReceiptData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.merchant)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(data.currency) \(data.amount, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(data.date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .frame(width: 120)
    }
}

// ImagePicker 已移至 ChatView.swift

// MARK: - 預覽

#Preview {
    PhotoAccountingView()
}
