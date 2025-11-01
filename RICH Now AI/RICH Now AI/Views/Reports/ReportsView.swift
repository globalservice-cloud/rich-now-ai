//
//  ReportsView.swift
//  RICH Now AI
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reports: [Report]
    @State private var selectedReportType: ReportType? = nil
    @State private var showingReportGenerator = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 報告類型選擇
                ReportTypeSelector(selectedType: $selectedReportType)
                
                // 報告列表
                if reports.isEmpty {
                    EmptyReportsView()
                } else {
                    ReportsListView(reports: reports)
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString("reports.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingReportGenerator = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingReportGenerator) {
                ReportGeneratorView { reportType in
                    generateReport(type: reportType)
                }
            }
        }
    }
    
    private func generateReport(type: ReportType) {
        // 實作報告生成邏輯
        Task {
            do {
                let report = try await createReport(type: type)
                await MainActor.run {
                    // 保存報告到 SwiftData
                    modelContext.insert(report)
                    try? modelContext.save()
                }
            } catch {
                print("Failed to generate report: \(error)")
            }
        }
    }
    
    private func createReport(type: ReportType) async throws -> Report {
        // 根據報告類型生成內容
        let title = LocalizationManager.shared.localizedString("report.type.\(type.rawValue)")
        let _ = try await generateReportContent(type: type)
        
        let report = Report(
            title: title,
            type: type,
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30天前
            endDate: Date()
        )
        
        // 模擬報告生成過程
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
        
        // 更新狀態為完成
        report.status = ReportStatus.completed.rawValue
        
        return report
    }
    
    private func generateReportContent(type: ReportType) async throws -> ReportContent {
        // 使用 AI 生成報告內容
        let _ = createReportPrompt(for: type)
        
        // 這裡應該調用 OpenAI API 生成內容
        // 暫時返回模擬內容
        return ReportContent(
            title: LocalizationManager.shared.localizedString("report.type.\(type.rawValue)"),
            summary: generateSummary(for: type),
            sections: generateSections(for: type),
            charts: generateCharts(for: type),
            insights: generateInsights(for: type),
            recommendations: generateRecommendations(for: type),
            biblicalPrinciples: generateBiblicalPrinciples(for: type)
        )
    }
    
    private func createReportPrompt(for type: ReportType) -> String {
        switch type {
        case .monthly_summary:
            return "生成月度財務總結報告，包含收入、支出、儲蓄和投資分析"
        case .goal_progress:
            return "分析財務目標進度，提供達成建議和調整方案"
        case .budget_analysis:
            return "分析預算執行情況，識別超支項目和節省機會"
        case .investment_performance:
            return "評估投資組合表現，提供優化建議和風險分析"
        case .debt_analysis:
            return "分析債務狀況，制定還債計劃和債務管理策略"
        case .financial_health:
            return "全面評估財務健康狀況，提供改善建議"
        case .vgla_insights:
            return "基於 VGLA 測驗結果，提供個性化財務洞察"
        case .custom:
            return "生成自訂財務報告，包含用戶指定的分析內容"
        }
    }
    
    private func generateSummary(for type: ReportType) -> String {
        switch type {
        case .monthly_summary:
            return "本月財務狀況良好，收入穩定增長，支出控制得當。建議繼續保持當前的理財策略。"
        case .goal_progress:
            return "財務目標進展順利，已完成 75% 的年度目標。建議調整部分策略以加速達成。"
        case .budget_analysis:
            return "預算執行情況良好，大部分類別都在控制範圍內。建議優化娛樂支出以增加儲蓄。"
        case .investment_performance:
            return "投資組合表現優異，年化收益率達到 12%。建議保持當前的資產配置策略。"
        case .debt_analysis:
            return "債務狀況持續改善，總債務減少 15%。建議繼續執行還債計劃。"
        case .financial_health:
            return "財務健康評分為 85 分，屬於良好水平。建議加強應急基金建設。"
        case .vgla_insights:
            return "基於您的 VGLA 類型，您是一個願景驅動的行動者，建議專注於長期投資策略。"
        case .custom:
            return "自訂報告已生成，包含您指定的所有分析內容。"
        }
    }
    
    private func generateSections(for type: ReportType) -> [ReportSection] {
        switch type {
        case .monthly_summary:
            return [
                ReportSection(title: "收入分析", content: "本月收入較上月增長 5%", data: ["增長率": "5%", "主要來源": "薪資"]),
                ReportSection(title: "支出分析", content: "支出控制在預算範圍內", data: ["預算執行率": "95%", "最大支出": "生活費"]),
                ReportSection(title: "儲蓄分析", content: "儲蓄率達到 25%", data: ["儲蓄率": "25%", "儲蓄金額": "NT$ 15,000"])
            ]
        case .goal_progress:
            return [
                ReportSection(title: "目標進度", content: "年度目標完成 75%", data: ["完成度": "75%", "剩餘時間": "3個月"]),
                ReportSection(title: "達成策略", content: "建議增加每月儲蓄金額", data: ["建議增加": "NT$ 2,000", "預期完成": "提前1個月"])
            ]
        default:
            return [
                ReportSection(title: "主要發現", content: "報告內容已生成", data: nil)
            ]
        }
    }
    
    private func generateCharts(for type: ReportType) -> [ReportChart] {
        switch type {
        case .monthly_summary:
            return [
                ReportChart(type: "pie", title: "支出分布", data: ["生活費": "40%", "娛樂": "20%", "儲蓄": "25%", "其他": "15%"]),
                ReportChart(type: "bar", title: "月度趨勢", data: ["1月": "100%", "2月": "105%", "3月": "110%"])
            ]
        case .investment_performance:
            return [
                ReportChart(type: "line", title: "投資收益", data: ["年初": "100%", "年中": "108%", "年末": "112%"])
            ]
        default:
            return [
                ReportChart(type: "bar", title: "分析結果", data: ["項目1": "80%", "項目2": "90%", "項目3": "75%"])
            ]
        }
    }
    
    private func generateInsights(for type: ReportType) -> [String] {
        switch type {
        case .monthly_summary:
            return [
                "收入穩定增長，顯示職業發展良好",
                "支出控制得當，儲蓄率維持在健康水平",
                "建議繼續保持當前的理財策略"
            ]
        case .goal_progress:
            return [
                "目標進展超預期，有望提前達成",
                "建議調整策略以挑戰更高目標",
                "保持當前的執行力度"
            ]
        default:
            return [
                "分析完成，發現多個改善機會",
                "建議持續監控和調整策略"
            ]
        }
    }
    
    private func generateRecommendations(for type: ReportType) -> [String] {
        switch type {
        case .monthly_summary:
            return [
                "繼續保持當前的收入增長趨勢",
                "優化支出結構，增加投資比例",
                "建立應急基金，目標3個月生活費"
            ]
        case .goal_progress:
            return [
                "增加每月儲蓄金額至 NT$ 2,000",
                "考慮額外收入來源",
                "調整投資策略以加速目標達成"
            ]
        default:
            return [
                "持續監控財務狀況",
                "定期檢視和調整策略",
                "尋求專業財務建議"
            ]
        }
    }
    
    private func generateBiblicalPrinciples(for type: ReportType) -> [String] {
        return [
            "「你要記念耶和華你的神，因為得貨財的力量是他給你的」- 申命記 8:18",
            "「殷勤人的手必掌權；懶惰的人必服苦」- 箴言 12:24",
            "「有施散的，卻更增添；有吝嗇過度的，反致窮乏」- 箴言 11:24"
        ]
    }
}

// MARK: - 報告類型選擇器

struct ReportTypeSelector: View {
    @Binding var selectedType: ReportType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    ReportTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
}

struct ReportTypeCard: View {
    let type: ReportType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(LocalizationManager.shared.localizedString("report.type.\(type.rawValue)"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 空報告視圖

struct EmptyReportsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(LocalizationManager.shared.localizedString("reports.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(LocalizationManager.shared.localizedString("reports.empty.description"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(LocalizationManager.shared.localizedString("reports.generate_first")) {
                // 生成報告功能
                print("Generate first report")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 報告列表視圖

struct ReportsListView: View {
    let reports: [Report]
    
    var body: some View {
        List(reports) { report in
            ReportRowView(report: report)
        }
        .listStyle(PlainListStyle())
    }
}

struct ReportRowView: View {
    let report: Report
    
    private func getReportIcon(for type: String) -> String {
        switch type {
        case "monthly_summary": return "calendar"
        case "financial_health": return "heart.fill"
        case "investment_analysis": return "chart.line.uptrend.xyaxis"
        case "expense_breakdown": return "chart.pie.fill"
        case "income_analysis": return "chart.bar.fill"
        case "goal_progress": return "target"
        case "custom": return "doc.text"
        default: return "doc"
        }
    }
    
    private func getReportColor(for type: String) -> Color {
        switch type {
        case "monthly_summary": return .blue
        case "financial_health": return .green
        case "investment_analysis": return .orange
        case "expense_breakdown": return .red
        case "income_analysis": return .purple
        case "goal_progress": return .cyan
        case "custom": return .gray
        default: return .blue
        }
    }
    
    private func getStatusColor(for status: String) -> Color {
        switch status {
        case "generating": return .orange
        case "completed": return .green
        case "failed": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 報告圖示
            Image(systemName: getReportIcon(for: report.type))
                .font(.title2)
                .foregroundColor(getReportColor(for: report.type))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(getReportColor(for: report.type).opacity(0.1))
                )
            
            // 報告資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(LocalizationManager.shared.localizedString("report.type.\(report.type)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(report.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 狀態指示器
            HStack(spacing: 4) {
                Circle()
                    .fill(getStatusColor(for: report.status))
                    .frame(width: 8, height: 8)
                
                Text(LocalizationManager.shared.localizedString("report.status.\(report.status)"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 報告生成器視圖

struct ReportGeneratorView: View {
    let onGenerate: (ReportType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(LocalizationManager.shared.localizedString("reports.generator.title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        ReportGeneratorCard(type: type) {
                            onGenerate(type)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }
            .navigationTitle(LocalizationManager.shared.localizedString("reports.generator.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString("common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReportGeneratorCard: View {
    let type: ReportType
    let onGenerate: () -> Void
    
    var body: some View {
        Button(action: onGenerate) {
            VStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.title)
                    .foregroundColor(type.color)
                
                Text(LocalizationManager.shared.localizedString("report.type.\(type.rawValue)"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(LocalizationManager.shared.localizedString("report.type.\(type.rawValue).description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 擴展

extension ReportType {
    var iconName: String {
        switch self {
        case .monthly_summary: return "calendar"
        case .goal_progress: return "target"
        case .budget_analysis: return "chart.pie"
        case .investment_performance: return "chart.line.uptrend.xyaxis"
        case .debt_analysis: return "exclamationmark.triangle"
        case .financial_health: return "heart"
        case .vgla_insights: return "brain.head.profile"
        case .custom: return "doc.text"
        }
    }
    
    var color: Color {
        switch self {
        case .monthly_summary: return .blue
        case .goal_progress: return .green
        case .budget_analysis: return .orange
        case .investment_performance: return .purple
        case .debt_analysis: return .red
        case .financial_health: return .pink
        case .vgla_insights: return .indigo
        case .custom: return .gray
        }
    }
}

extension ReportStatus {
    var color: Color {
        switch self {
        case .generating: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    ReportsView()
}
