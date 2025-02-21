//
//  MiniPlayerView.swift
//  swae
//
//  Created by Suhail Saqan on 2/16/25.
//


import SwiftUI
import NostrSDK
import Kingfisher

struct PlayerView: View {
    @EnvironmentObject var orientationMonitor: OrientationMonitor
    
    var size: CGSize
    @Binding var playerConfig: PlayerConfig
    var close: () -> ()
    
    let miniPlayerHeight: CGFloat = 50
    let playerHeight: CGFloat = 250
    
    @State private var videoPlayerViewSize: CGSize = .zero
    
    var body: some View {
        let progress = playerConfig.progress > 0.7 ? ((playerConfig.progress - 0.7) / 0.3) : 0
        
        VStack(spacing: 0) {
            VStack {
                ZStack(alignment: .top) {
                    GeometryReader {
                        let size = $0.size
                        let width = size.width - 120
                        let height = size.height
                        
                        VideoPlayer()
                            .frame(width: 120 + (width - (width * progress)),
                                   height: height)
                    }
                    
                    if !orientationMonitor.isLandscape {
                        PlayerMinifiedContent()
                            .padding(.leading, 130)
                            .padding(.trailing, 15)
                            .foregroundStyle(Color.primary)
                            .opacity(progress)
                    }
                }
                .frame(minHeight: miniPlayerHeight, maxHeight: orientationMonitor.isLandscape ? .infinity : playerHeight)
                .padding(.top, ((UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets.top ?? 0) * (1 - playerConfig.progress))
                .zIndex(2)
                
                if !orientationMonitor.isLandscape {
                    if let playerItem = playerConfig.selectedLiveActivitiesEvent {
                        LiveChatView(liveActivitiesEvent: playerItem)
                            .opacity(1.0 - (playerConfig.progress * 1.6))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
        .clipped()
        .contentShape(.rect)
        .offset(y: playerConfig.progress * -tabBarHeight)
        .frame(height: size.height - playerConfig.position, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .gesture(
            DragGesture()
                .onChanged({ value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                    
                    let height = playerConfig.lastPosition + value.translation.height
                    playerConfig.position = min(height, size.height - miniPlayerHeight)
                    generateProgress()
                })
                .onEnded({ value in
                    let start = value.startLocation.y
                    guard start < playerHeight || start > (size.height - (tabBarHeight + miniPlayerHeight)) else { return }
                    
                    let velocity = value.velocity.height * 5
                    withAnimation(.smooth(duration: 0.3)) {
                        if (playerConfig.position + velocity) > (size.height * 0.6) {
                            playerConfig.position = size.height - miniPlayerHeight
                            playerConfig.lastPosition = playerConfig.position
                            playerConfig.progress = 1
                        } else {
                            playerConfig.resetPosition()
                        }
                    }
                })
                .simultaneously(with: TapGesture().onEnded({ _ in
                    withAnimation(.smooth(duration: 0.3)) {
                        playerConfig.resetPosition()
                    }
                }))
        )
        /// Sliding In out
        .transition(.offset(y: playerConfig.progress == 1 ? tabBarHeight : size.height))
        .onChange(of: playerConfig.selectedLiveActivitiesEvent, initial: false) { oldValue, newValue in
            withAnimation(.smooth(duration: 0.3)) {
                playerConfig.resetPosition()
            }
        }
    }
    
    // VideoPlayerView
    @ViewBuilder
    func VideoPlayer() -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            VStack {
                if let url = playerConfig.selectedLiveActivitiesEvent?.recording ?? playerConfig.selectedLiveActivitiesEvent?.streaming {
                    ZStack {
                        Rectangle()
                            .fill(Color.blue)
                        VideoPlayerView(url: url, onDragUp: fullScreen)
                    }
                    // Use the size provided by VideoPlayerView.
                    .frame(width: videoPlayerViewSize.width, height: videoPlayerViewSize.height)
                    .aspectRatio(contentMode: .fit)
                    .onPreferenceChange(VideoPlayerViewSizeKey.self) { newSize in
                        videoPlayerViewSize = newSize
                    }
                } else {
                    VStack {
                        Text("NO RECORDING NOR STREAM")
                            .font(.headline)
                            .foregroundColor(.purple)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: size.width, height: size.height)
        }
    }
    
    func fullScreen() {
        
    }
    
    @ViewBuilder
    func PlayerMinifiedContent() -> some View {
        if let playerItem = playerConfig.selectedLiveActivitiesEvent {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(playerItem.title ?? "")
                        .font(.callout)
                        .textScale(.secondary)
                        .lineLimit(1)
                    
//                    Text(playerItem.author)
//                        .font(.caption2)
//                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
                .frame(maxHeight: miniPlayerHeight)
                
                Spacer()
                
                Button(action: {}, label: {
                    Image(systemName: "pause.fill")
                        .font(.title)
                        .frame(width: 35, height: 35)
                        .contentShape(.rect)
                })
                
                Button(action: {
                    close()
                }, label: {
                    Image(systemName: "xmark")
                        .font(.title)
                        .frame(width: 35, height: 35)
                        .contentShape(.rect)
                })
            }
        }
    }
    
    func generateProgress() {
        let progress = max(min(playerConfig.position / (size.height - miniPlayerHeight), 1.0), .zero)
        playerConfig.progress = progress
    }
}
