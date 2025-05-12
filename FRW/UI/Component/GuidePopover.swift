//
//  GuidePopover.swift
//  FRW
//
//  Created by cat on 5/12/25.
//

import SwiftUI

// MARK: - Helper

struct CaptureFrameModifier: ViewModifier {
    @Binding var frame: CGRect?
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
                }
            )
            .onPreferenceChange(FramePreferenceKey.self) { value in
                self.frame = value
            }
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension View {
    func captureFrame(_ frame: Binding<CGRect?>) -> some View {
        modifier(CaptureFrameModifier(frame: frame))
    }
}

private struct GuideTargetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func guideTarget(id: String) -> some View {
        background(
            GeometryReader { proxy in
                let rect = proxy.frame(in: .global)
                return Color.clear
                    .preference(key: GuideTargetPreferenceKey.self, value: [id: rect])
            }
        )
    }
}

// MARK: - GuidePopover

struct GuidePopover<Content: View, Popover: View>: View {
    @Binding var isPresented: Bool
    let targetId: String
    let content: () -> Content
    let popoverContent: () -> Popover

    @State private var frames: [String: CGRect] = [:]
    @State private var contentSize: CGSize = .zero

    var body: some View {
        ZStack {
            content()
            if isPresented, let frame = frames[targetId] {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { isPresented = false }
                GeometryReader { proxy in
                    let screen = proxy.frame(in: .global)
                    let showBelow = frame.maxY + contentSize.height < screen.maxY
                    let y = showBelow
                        ? floor(frame.maxY - contentSize.height / 2)
                        : ceil(frame.minY - contentSize.height / 2)
                    let x = min(max(frame.midX, screen.minX + contentSize.width / 2), screen.maxX - contentSize.width / 2)
                    popoverContent()
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { contentSize = geo.size }
                                    .onChange(of: geo.size) { newValue in contentSize = newValue }
                            }
                        )
                        .position(x: x, y: y)
                }
            }
        }
        .onPreferenceChange(GuideTargetPreferenceKey.self) { value in
            self.frames = value
        }
    }
}

struct GuidePopoverDemo: View {
    @State private var showPopover = false

    var body: some View {
        VStack {
            GuidePopover(isPresented: $showPopover, targetId: "btn") {
                VStack {
                    Spacer()
                    Button("click me popup") {
                        showPopover = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .guideTarget(id: "btn")
                    Spacer()
                }
            } popoverContent: {
                Text("Guide for new user")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 8)
            }
        }
    }
}

struct GuidePopoverDemo_Previews: PreviewProvider {
    static var previews: some View {
        GuidePopoverDemo()
    }
}
