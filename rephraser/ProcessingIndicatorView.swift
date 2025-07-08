//
//  ProcessingIndicatorView.swift
//  rephraser
//
//  Created by Rok Hoang on 7/8/25.
//

import SwiftUI

struct ProcessingIndicatorView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var opacity: Double = 0.0
    
    let message: String
    let isVisible: Bool
    
    var body: some View {
        ZStack {
            if isVisible {
                // Background blur
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // Prevent interaction with background
                    }
                
                // Processing card
                VStack(spacing: 16) {
                    // Animated loading indicator
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topTrailing,
                                    endPoint: .bottomLeading
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    
                    // Message text
                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Status text
                    Text("Processing with Claude AI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
                )
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(opacity)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        opacity = 1.0
                    }
                    isAnimating = true
                    pulseScale = 1.1
                }
                .onDisappear {
                    isAnimating = false
                    pulseScale = 1.0
                }
            }
        }
        .onChange(of: isVisible) { _, newValue in
            if !newValue {
                withAnimation(.easeInOut(duration: 0.2)) {
                    opacity = 0.0
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1.0
                }
            }
        }
    }
}

// Window controller for the processing indicator
class ProcessingIndicatorWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.level = .floating
        self.ignoresMouseEvents = false
        
        // Center the window on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = self.frame
            let centeredRect = NSRect(
                x: screenRect.midX - windowRect.width / 2,
                y: screenRect.midY - windowRect.height / 2,
                width: windowRect.width,
                height: windowRect.height
            )
            self.setFrame(centeredRect, display: true)
        }
    }
}

// Manager for showing/hiding the processing indicator
class ProcessingIndicatorManager: ObservableObject {
    private var indicatorWindow: ProcessingIndicatorWindow?
    @Published var isVisible = false
    @Published var message = "Rephrasing text..."
    
    func show(message: String = "Rephrasing text...") {
        DispatchQueue.main.async {
            self.message = message
            self.isVisible = true
            
            if self.indicatorWindow == nil {
                self.indicatorWindow = ProcessingIndicatorWindow()
                let hostingView = NSHostingView(
                    rootView: ProcessingIndicatorView(
                        message: self.message,
                        isVisible: self.isVisible
                    )
                    .environmentObject(self)
                )
                self.indicatorWindow?.contentView = hostingView
            }
            
            self.indicatorWindow?.makeKeyAndOrderFront(nil)
            self.indicatorWindow?.orderFrontRegardless()
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.isVisible = false
            
            // Delay hiding the window to allow for exit animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.indicatorWindow?.orderOut(nil)
                self.indicatorWindow = nil
            }
        }
    }
    
    func updateMessage(_ newMessage: String) {
        DispatchQueue.main.async {
            self.message = newMessage
        }
    }
}