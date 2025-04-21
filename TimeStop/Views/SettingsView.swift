import SwiftUI

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
                .cornerRadius(16)
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
                    .cornerRadius(16)
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
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    
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
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                
                Spacer()
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

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .environmentObject(ThemeManager())
} 