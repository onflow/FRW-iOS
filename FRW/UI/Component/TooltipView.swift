//
//  TooltipView.swift
//  FRW
//
//  Created by cat on 5/12/25.
//

import SwiftUI

struct TooltipView<Content: View>: View {
    let alignment: Edge
    @Binding var isVisible: Bool
    let content: () -> Content
    let arrowOffset = CGFloat(8)

    private var oppositeAlignment: Alignment {
        let result: Alignment
        switch alignment {
        case .top: result = .bottom
        case .bottom: result = .top
        case .leading: result = .trailing
        case .trailing: result = .leading
        }
        return result
    }

    private var theHint: some View {
        content()
            .fixedSize()
    }

    var body: some View {
        if isVisible {
            GeometryReader { proxy1 in

                // Use a hidden version of the hint to form the footprint
                theHint
                    .hidden()
                    .overlay {
                        GeometryReader { proxy2 in

                            // The visible version of the hint
                            theHint
                                .drawingGroup()
                                .shadow(radius: 4)
                                // Center the hint over the source view
                                .offset(
                                    x: -(proxy2.size.width / 2) + (proxy1.size.width / 2),
                                    y: -(proxy2.size.height / 2) + (proxy1.size.height / 2)
                                )
                                // Move the hint to the required edge
                                .offset(x: alignment == .leading ? (-proxy2.size.width / 2) - (proxy1.size.width / 2) : 0)
                                .offset(x: alignment == .trailing ? (proxy2.size.width / 2) + (proxy1.size.width / 2) : 0)
                                .offset(y: alignment == .top ? (-proxy2.size.height / 2) - (proxy1.size.height / 2) : 0)
                                .offset(y: alignment == .bottom ? (proxy2.size.height / 2) + (proxy1.size.height / 2) : 0)
                        }
                    }
            }
            .onTapGesture {
                isVisible.toggle()
            }
        }
    }
}

private struct HintBox: View {
    @State private var showTooltip = true

    var body: some View {
        VStack {
            Text("Text here")
                .overlay {
                    TooltipView(
                        alignment: .bottom,
                        isVisible: $showTooltip
                    ) {
                        Text("Tokens with less than 1$ USD balance")
                            .font(.system(size: 10))
                            .padding(4)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
                .onTapGesture {
                    showTooltip.toggle()
                }
        }
    }
}

struct Popover_Previews: PreviewProvider {
    static var previews: some View {
        HintBox()
    }
}
