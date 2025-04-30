import SwiftUI
import AudioToolbox

struct SettingsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingLogoutAlert = false
    @State private var showRingtoneModal = false
    
    var body: some View {
        ZStack {
            // 背景层
            VStack(spacing: 0) {
                // 上部分主题背景色
                themeManager.colors.background
                    .frame(height: 260)
                
                // 下部分背景色
                themeManager.colors.secondaryBackground
            }
            .edgesIgnoringSafeArea(.all)
            
            // 内容层
            VStack(spacing: 0) {
                // 标题
                Text("个人设置")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(themeManager.colors.text)
                    .padding(.top, 30)
                
                // 添加ScrollView以确保内容可滚动
                ScrollView {
                    VStack(spacing: 0) {
                // 用户信息卡片
                VStack(alignment: .leading, spacing: 8) {
                    if let user = viewModel.currentUser {
                        Text(user.username)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                            .padding(.bottom, 4)
                            
                        Text("等级: \(user.level)")
                            .font(.system(size: 17))
                            .foregroundColor(themeManager.colors.text)
                            
                        Text("总专注时间: \(user.totalFocusTime) 分钟")
                            .font(.system(size: 17))
                            .foregroundColor(themeManager.colors.text)
                            
                        Text("完成任务数: \(user.completedTasks)")
                            .font(.system(size: 17))
                            .foregroundColor(themeManager.colors.text)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(themeManager.colors.secondaryBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, 25)
                
                // 设置选项列表
                VStack(spacing: 15) {
                    // 应用设置卡片
                    VStack(spacing: 0) {
                        Text("应用设置")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 12)
                        
                        // 音效开关
                        Toggle(isOn: $viewModel.soundEnabled) {
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.soundEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                                    .foregroundColor(viewModel.soundEnabled ? themeManager.colors.primary : themeManager.colors.secondaryText)
                                
                                Text("按钮音效")
                                    .font(.system(size: 17))
                                    .foregroundColor(themeManager.colors.text)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: themeManager.colors.primary))
                        .onChange(of: viewModel.soundEnabled) { newValue in
                            // 直接保存设置，不调用toggleSoundEnabled，避免循环调用
                            UserDefaults.standard.set(newValue, forKey: "soundEnabled")
                        }
                        
                        // 分隔线
                        Divider()
                            .background(themeManager.colors.text.opacity(0.1))
                            .padding(.vertical, 8)
                        
                        // 铃声选择选项 - 改为点击后弹出弹窗
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(themeManager.colors.primary)
                            
                            Text("倒计时结束铃声")
                                .font(.system(size: 17))
                                .foregroundColor(themeManager.colors.text)
                            
                            Spacer()
                            
                            // 显示当前选择的铃声
                            Text(viewModel.currentRingtone.name)
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.colors.secondaryText)
                                .padding(.trailing, 4)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.colors.secondaryText)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewModel.soundEnabled {
                                // 播放按钮音效
                                viewModel.playButtonSound()
                                // 显示铃声选择弹窗
                                showRingtoneModal = true
                            }
                        }
                        .disabled(!viewModel.soundEnabled)
                        .opacity(viewModel.soundEnabled ? 1.0 : 0.5)
                    }
                    .padding(20)
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    
                    // 主题设置卡片
                    VStack(spacing: 0) {
                        Text("主题设置")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(themeManager.colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 12)
                        
                        // 主题选择列表
                        ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                            Button(action: {
                                withAnimation {
                                    themeManager.switchTheme(to: theme)
                                }
                                
                                // 播放按钮音效
                                viewModel.playButtonSound()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(theme.colors.primary)
                                        .frame(width: 20, height: 20)
                                    
                                    Text(theme.rawValue)
                                        .font(.system(size: 17))
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                    
                                    if themeManager.currentTheme == theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(themeManager.colors.primary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            
                            if theme != ThemeManager.AppTheme.allCases.last {
                                Divider()
                                    .background(themeManager.colors.text.opacity(0.1))
                            }
                        }
                    }
                    .padding(20)
                    .background(themeManager.colors.secondaryBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    
                    // 添加缓存管理卡片
                    CacheManagementCard(viewModel: viewModel, themeManager: themeManager)
                    
                    // 退出登录按钮
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 17))
                            Text("退出登录")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(Color.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(themeManager.colors.secondaryBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                        // 添加底部间距，确保内容不会被TabBar遮挡
                        .padding(.bottom, 80)
                    }
                }
            }
            .padding(.top, 60)
        }
        .alert("退出登录", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("确定", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .sheet(isPresented: $showRingtoneModal) {
            RingtoneSelectionView(
                selectedRingtoneID: viewModel.selectedRingtoneID,
                ringtones: viewModel.availableRingtones,
                onSelect: { id in
                    viewModel.selectRingtone(id: id)
                    viewModel.playButtonSound()
                    showRingtoneModal = false
                },
                onPreview: { id in
                    viewModel.playRingtoneSample(id: id)
                },
                onDismiss: {
                    showRingtoneModal = false
                }
            )
            .environmentObject(themeManager)
        }
    }
}

// 铃声选择弹窗
struct RingtoneSelectionView: View {
    var selectedRingtoneID: String
    var ringtones: [AppViewModel.Ringtone]
    var onSelect: (String) -> Void
    var onPreview: (String) -> Void
    var onDismiss: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // 固定使用白色背景，确保内容清晰可见
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(ringtones) { ringtone in
                        HStack {
                            // 试听按钮
                            Button(action: {
                                onPreview(ringtone.id)
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(themeManager.colors.primary)
                                    .padding(5)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            // 铃声名称
                            Text(ringtone.name)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.black) // 固定使用黑色文字
                            
                            Spacer()
                            
                            // 选中标记 - 所有选项都显示圆形按钮
                            if ringtone.id == selectedRingtoneID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(themeManager.colors.primary)
                                    .font(.system(size: 22))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(Color.gray.opacity(0.5))
                                    .font(.system(size: 22))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(ringtone.id)
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white) // 固定使用白色背景
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("选择铃声")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onDismiss()
                    }
                    .foregroundColor(.black) // 将取消按钮文字颜色改为黑色
                }
            }
        }
        .preferredColorScheme(.light) // 固定使用浅色模式
    }
}

// 添加缓存管理卡片视图
struct CacheManagementCard: View {
    @ObservedObject var viewModel: AppViewModel
    @ObservedObject var themeManager: ThemeManager
    
    @State private var isClearing: Bool = false
    @State private var showingClearConfirmation: Bool = false
    @State private var showingClearSuccess: Bool = false
    @State private var clearError: String? = nil
    @State private var selectedCacheType: AppViewModel.CacheType = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text("缓存管理")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(themeManager.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
            
            // 缓存大小信息
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("当前缓存大小")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.colors.text)
                    
                    Text(String(format: "%.2f MB", viewModel.cacheStatus.totalSizeMB))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(
                            viewModel.cacheStatus.totalSizeMB > 50 ? .red :
                            viewModel.cacheStatus.totalSizeMB > 20 ? .orange : themeManager.colors.primary
                        )
                }
                
                Spacer()
                
                // 上次清理时间
                if let lastCleanDate = viewModel.cacheStatus.lastCleanDate {
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("上次清理")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                        
                        Text(formatDate(lastCleanDate))
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.colors.secondaryText)
                    }
                }
            }
            .padding(.vertical, 10)
            
            // 清理选项
            VStack(spacing: 10) {
                // 全部清理按钮
                Button(action: {
                    selectedCacheType = .all
                    showingClearConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("清理全部缓存")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(themeManager.colors.primary)
                    .cornerRadius(8)
                }
                .disabled(isClearing)
                
                // 选择性清理按钮
                HStack(spacing: 10) {
                    // 音频缓存按钮
                    Button(action: {
                        selectedCacheType = .audio
                        showingClearConfirmation = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 14))
                            Text("音频")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .disabled(isClearing)
                    
                    // 录音文件按钮
                    Button(action: {
                        selectedCacheType = .recordings
                        showingClearConfirmation = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "mic")
                                .font(.system(size: 14))
                            Text("录音")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(isClearing)
                    
                    // 临时文件按钮
                    Button(action: {
                        selectedCacheType = .tempFiles
                        showingClearConfirmation = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "doc")
                                .font(.system(size: 14))
                            Text("临时文件")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    .disabled(isClearing)
                    
                    // Metal缓存按钮
                    Button(action: {
                        selectedCacheType = .metal
                        showingClearConfirmation = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "paintbrush")
                                .font(.system(size: 14))
                            Text("渲染缓存")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.purple)
                        .cornerRadius(8)
                    }
                    .disabled(isClearing)
                }
            }
            .padding(.vertical, 10)
            
            // 刷新缓存大小按钮
            Button(action: {
                // 播放按钮音效
                viewModel.playButtonSound()
                
                // 刷新缓存大小信息
                viewModel.calculateCacheSize { _ in }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                    Text("刷新缓存信息")
                        .font(.system(size: 14))
                }
                .foregroundColor(themeManager.colors.text)
                .padding(.vertical, 8)
            }
            .padding(.top, 10)
            
            // 清理进度指示器
            if isClearing {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.primary))
                    
                    Text("正在清理缓存...")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.colors.secondaryText)
                }
                .padding(.top, 10)
            }
            
            // 错误信息
            if let error = clearError {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.top, 10)
            }
        }
        .padding(20)
        .background(themeManager.colors.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .alert(isPresented: $showingClearConfirmation) {
            Alert(
                title: Text("确认清理缓存"),
                message: Text(getCacheTypeDescription()),
                primaryButton: .destructive(Text("清理")) {
                    clearCache()
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .alert("清理完成", isPresented: $showingClearSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("缓存已成功清理，总空间节省了 \(String(format: "%.2f", viewModel.cacheStatus.totalSizeMB)) MB。")
        }
        .onAppear {
            // 刷新缓存大小信息
            viewModel.calculateCacheSize { _ in }
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    // 获取缓存类型描述
    private func getCacheTypeDescription() -> String {
        switch selectedCacheType {
        case .all:
            return "这将清理所有类型的缓存，包括音频、录音、临时文件和渲染缓存。"
        case .audio:
            return "这将清理音频相关的缓存文件。"
        case .recordings:
            return "这将清理所有录音文件。"
        case .tempFiles:
            return "这将清理应用产生的临时文件。"
        case .metal:
            return "这将清理Metal渲染缓存，可能解决渲染问题。"
        }
    }
    
    // 清理缓存
    private func clearCache() {
        // 开始清理
        isClearing = true
        clearError = nil
        
        // 播放按钮音效
        viewModel.playButtonSound()
        
        // 调用ViewModel的清理方法
        viewModel.clearCache(type: selectedCacheType) { success, error in
            // 清理完成
            isClearing = false
            
            if success {
                // 播放成功音效
                AudioServicesPlaySystemSound(1057)
                
                // 显示成功提示
                showingClearSuccess = true
            } else {
                // 设置错误信息
                if let error = error {
                    clearError = "清理失败: \(error.localizedDescription)"
                } else {
                    clearError = "清理过程中发生未知错误"
                }
                
                // 播放错误音效
                AudioServicesPlaySystemSound(1073)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 