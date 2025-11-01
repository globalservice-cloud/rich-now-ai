//
//  TransactionParserTestView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import Combine

struct TransactionParserTestView: View {
    @StateObject private var transactionParser = TransactionParser()
    @State private var testInput = ""
    @State private var parsedResult: ParsedTransaction?
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var testCases: [TestCase] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 測試輸入區域
                    testInputSection
                    
                    // 解析結果顯示
                    if let result = parsedResult {
                        resultDisplaySection(result: result)
                    }
                    
                    // 錯誤訊息顯示
                    if let error = errorMessage {
                        errorDisplaySection(error: error)
                    }
                    
                    // 預設測試案例
                    testCasesSection
                }
                .padding()
            }
            .navigationTitle("Transaction Parser Test")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            setupTestCases()
        }
    }
    
    // MARK: - 測試輸入區域
    
    private var testInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("測試輸入")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("輸入自然語言交易描述...", text: $testInput, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            Button("解析交易") {
                parseTransaction()
            }
            .buttonStyle(.borderedProminent)
            .disabled(testInput.isEmpty || isParsing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 解析結果顯示
    
    private func resultDisplaySection(result: ParsedTransaction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解析結果")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("金額:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(result.amount, specifier: "%.2f")")
                        .fontWeight(.bold)
                        .foregroundColor(result.type == .income ? .green : .red)
                }
                
                HStack {
                    Text("類型:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.type == .income ? "收入" : "支出")
                        .fontWeight(.bold)
                        .foregroundColor(result.type == .income ? .green : .red)
                }
                
                HStack {
                    Text("類別:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.category)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("描述:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.description)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("日期:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(result.date, style: .date)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 錯誤訊息顯示
    
    private func errorDisplaySection(error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("解析錯誤")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(error)
                .font(.body)
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - 預設測試案例
    
    private var testCasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預設測試案例")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(testCases, id: \.id) { testCase in
                    Button(action: {
                        testInput = testCase.input
                        parseTransaction()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(testCase.input)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text(testCase.expectedCategory)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 解析交易
    
    private func parseTransaction() {
        guard !testInput.isEmpty else { return }
        
        isParsing = true
        errorMessage = nil
        parsedResult = nil
        
        Task {
            do {
                let result = try await transactionParser.parseTransaction(from: testInput)
                await MainActor.run {
                    self.parsedResult = result
                    self.isParsing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isParsing = false
                }
            }
        }
    }
    
    // MARK: - 設置測試案例
    
    private func setupTestCases() {
        testCases = [
            // 中文測試案例
            TestCase(input: "今天花了 100 元買咖啡", expectedCategory: "餐飲"),
            TestCase(input: "昨天收到 5000 元薪水", expectedCategory: "薪資"),
            TestCase(input: "剛剛支出 200 塊停車費", expectedCategory: "交通"),
            TestCase(input: "買了 1500 元衣服", expectedCategory: "購物"),
            TestCase(input: "支付 3000 元房租", expectedCategory: "居住"),
            TestCase(input: "收到 500 元股息", expectedCategory: "投資收益"),
            TestCase(input: "花了 800 元看電影", expectedCategory: "娛樂"),
            TestCase(input: "支出 2000 元學費", expectedCategory: "教育"),
            TestCase(input: "支付 500 元醫療費", expectedCategory: "醫療"),
            TestCase(input: "收到 1000 元禮物", expectedCategory: "禮物"),
            
            // 英文測試案例
            TestCase(input: "spent $50 on lunch today", expectedCategory: "餐飲"),
            TestCase(input: "received $1000 salary yesterday", expectedCategory: "薪資"),
            TestCase(input: "paid $20 for parking just now", expectedCategory: "交通"),
            TestCase(input: "bought $200 clothes", expectedCategory: "購物"),
            TestCase(input: "paid $500 rent", expectedCategory: "居住"),
            TestCase(input: "received $100 dividend", expectedCategory: "投資收益"),
            TestCase(input: "spent $30 on movie", expectedCategory: "娛樂"),
            TestCase(input: "paid $1000 tuition", expectedCategory: "教育"),
            TestCase(input: "paid $200 medical bill", expectedCategory: "醫療"),
            TestCase(input: "received $50 gift", expectedCategory: "禮物"),
            
            // 混合語言測試案例
            TestCase(input: "bought 星巴克 coffee for $5", expectedCategory: "餐飲"),
            TestCase(input: "收到 amazon 網購 $200", expectedCategory: "購物"),
            TestCase(input: "paid uber $15", expectedCategory: "交通"),
            TestCase(input: "花了 netflix $10", expectedCategory: "娛樂"),
            TestCase(input: "收到 spotify $5", expectedCategory: "娛樂"),
            
            // 複雜語法測試案例
            TestCase(input: "今天早上花了 150 元在麥當勞買早餐", expectedCategory: "餐飲"),
            TestCase(input: "昨天下午收到公司發的 3000 元獎金", expectedCategory: "薪資"),
            TestCase(input: "剛剛支付了 500 元停車費給停車場", expectedCategory: "交通"),
            TestCase(input: "上週買了 2000 元的新衣服", expectedCategory: "購物"),
            TestCase(input: "這個月房租 8000 元已經付了", expectedCategory: "居住"),
            
            // 時間表達測試案例
            TestCase(input: "上週花了 300 元看電影", expectedCategory: "娛樂"),
            TestCase(input: "上個月收到 5000 元薪水", expectedCategory: "薪資"),
            TestCase(input: "下週要付 2000 元學費", expectedCategory: "教育"),
            TestCase(input: "下個月房租 8000 元", expectedCategory: "居住"),
            TestCase(input: "這個週買了 500 元食物", expectedCategory: "餐飲"),
            TestCase(input: "最近花了 1000 元醫療費", expectedCategory: "醫療"),
            TestCase(input: "之前買了 3000 元電腦", expectedCategory: "購物"),
            TestCase(input: "後來收到 200 元股息", expectedCategory: "投資收益"),
            
            // 動詞變化測試案例
            TestCase(input: "購買了 1500 元衣服", expectedCategory: "購物"),
            TestCase(input: "購入 2000 元家具", expectedCategory: "購物"),
            TestCase(input: "花 500 元吃飯", expectedCategory: "餐飲"),
            TestCase(input: "付了 300 元停車費", expectedCategory: "交通"),
            TestCase(input: "付 8000 元房租", expectedCategory: "居住"),
            TestCase(input: "繳了 2000 元學費", expectedCategory: "教育"),
            TestCase(input: "繳 500 元電費", expectedCategory: "居住"),
            TestCase(input: "賺 3000 元獎金", expectedCategory: "薪資"),
            TestCase(input: "獲得 1000 元禮物", expectedCategory: "禮物"),
            TestCase(input: "領到 5000 元薪水", expectedCategory: "薪資"),
            TestCase(input: "領 200 元股息", expectedCategory: "投資收益"),
            
            // 多貨幣格式測試案例
            TestCase(input: "花了 €50 買咖啡", expectedCategory: "餐飲"),
            TestCase(input: "收到 ¥5000 薪水", expectedCategory: "薪資"),
            TestCase(input: "支付 £30 停車費", expectedCategory: "交通"),
            TestCase(input: "買了 $100 衣服", expectedCategory: "購物"),
            TestCase(input: "收到 EUR 200 股息", expectedCategory: "投資收益"),
            TestCase(input: "花了 JPY 1000 吃飯", expectedCategory: "餐飲"),
            TestCase(input: "支付 GBP 50 學費", expectedCategory: "教育"),
            TestCase(input: "買了 USD 200 電腦", expectedCategory: "購物"),
            
            // 英文時間表達測試案例
            TestCase(input: "last week spent $100 on groceries", expectedCategory: "餐飲"),
            TestCase(input: "last month received $3000 salary", expectedCategory: "薪資"),
            TestCase(input: "next week will pay $2000 rent", expectedCategory: "居住"),
            TestCase(input: "next month will buy $500 clothes", expectedCategory: "購物"),
            TestCase(input: "this week spent €50 on transport", expectedCategory: "交通"),
            TestCase(input: "this month received ¥10000 bonus", expectedCategory: "薪資"),
            TestCase(input: "recently bought £100 books", expectedCategory: "教育"),
            TestCase(input: "earlier paid $300 medical bill", expectedCategory: "醫療"),
            TestCase(input: "later received $200 dividend", expectedCategory: "投資收益"),
            
            // 英文動詞變化測試案例
            TestCase(input: "purchased $500 furniture", expectedCategory: "購物"),
            TestCase(input: "spend €30 on lunch", expectedCategory: "餐飲"),
            TestCase(input: "pay £50 for parking", expectedCategory: "交通"),
            TestCase(input: "got ¥5000 salary", expectedCategory: "薪資"),
            TestCase(input: "get $200 bonus", expectedCategory: "薪資"),
            TestCase(input: "gained €100 dividend", expectedCategory: "投資收益"),
            TestCase(input: "gain £50 interest", expectedCategory: "投資收益"),
            TestCase(input: "earn $3000 monthly", expectedCategory: "薪資"),
            
            // 邊界情況測試案例
            TestCase(input: "花了 0.5 元", expectedCategory: "其他"),
            TestCase(input: "收到 1000000 元", expectedCategory: "其他"),
            TestCase(input: "支出 負100 元", expectedCategory: "其他"),
            TestCase(input: "買了 無價 的東西", expectedCategory: "其他"),
            TestCase(input: "花了 很多 錢", expectedCategory: "其他")
        ]
    }
}

// MARK: - 測試案例結構

struct TestCase {
    let id = UUID()
    let input: String
    let expectedCategory: String
}

// MARK: - 預覽

#Preview {
    TransactionParserTestView()
}
