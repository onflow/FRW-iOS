import SwiftUI

// MARK: - PositionType

// There are two type of positioning views - one that scrolls with the content,
// and one that stays fixed
private enum PositionType {
    case fixed, moving
}

// MARK: - Position

// This struct is the currency of the Preferences, and has a type
// (fixed or moving) and the actual Y-axis value.
// It's Equatable because Swift requires it to be.
private struct Position: Equatable {
    let type: PositionType
    let y: CGFloat
}

// MARK: - PositionPreferenceKey

// This might seem weird, but it's necessary due to the funny nature of
// how Preferences work. We can't just store the last position and merge
// it with the next one - instead we have a queue of all the latest positions.
private struct PositionPreferenceKey: PreferenceKey {
    typealias Value = [Position]

    static var defaultValue = [Position]()

    static func reduce(value: inout [Position], nextValue: () -> [Position]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - PositionIndicator

private struct PositionIndicator: View {
    let type: PositionType

    var body: some View {
        GeometryReader { proxy in
            // the View itself is an invisible Shape that fills as much as possible
            Color.clear
                // Compute the top Y position and emit it to the Preferences queue
                .preference(
                    key: PositionPreferenceKey.self,
                    value: [Position(type: type, y: proxy.frame(in: .global).minY)]
                )
        }
    }
}

// Callback that'll trigger once refreshing is done
public typealias RefreshComplete = () -> Void

// The actual refresh action that's called once refreshing starts. It has the
// RefreshComplete callback to let the refresh action let the View know
// once it's done refreshing.
public typealias OnRefresh = (@escaping RefreshComplete) -> Void

// The offset threshold. 68 is a good number, but you can play
// with it to your liking.
public let defaultRefreshThreshold: CGFloat = 60

// MARK: - RefreshState

// Tracks the state of the RefreshableScrollView - it's either:
// 1. waiting for a scroll to happen
// 2. has been primed by pulling down beyond THRESHOLD
// 3. is doing the refreshing.
public enum RefreshState {
    case waiting, primed, loading
}

// ViewBuilder for the custom progress View, that may render itself
// based on the current RefreshState.
public typealias RefreshProgressBuilder<Progress: View> = (RefreshState) -> Progress

// Default color of the rectangle behind the progress spinner
public let defaultLoadingViewBackgroundColor = Color.Theme.BG.bg1

// MARK: - RefreshableScrollView

public struct RefreshableScrollView<Progress, Content>: View where Progress: View, Content: View {
    // MARK: Lifecycle

    // We use a custom constructor to allow for usage of a @ViewBuilder for the content
    public init(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder progress: @escaping RefreshProgressBuilder<Progress>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.loadingViewBackgroundColor = loadingViewBackgroundColor
        self.threshold = threshold
        self.onRefresh = onRefresh
        self.progress = progress
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        // The root view is a regular ScrollView
        ScrollView(showsIndicators: showsIndicators) {
            // The ZStack allows us to position the PositionIndicator,
            // the content and the loading view, all on top of each other.
            ZStack(alignment: .top) {
                // The moving positioning indicator, that sits at the top
                // of the ScrollView and scrolls down with the content
                PositionIndicator(type: .moving)
                    .frame(height: 0)

                // Your ScrollView content. If we're loading, we want
                // to keep it below the loading view, hence the alignmentGuide.
                content()
                    .alignmentGuide(.top, computeValue: { _ in
                        (state == .loading) ? -threshold + max(0, offset) : 0
                    })

                // The loading view. It's offset to the top of the content unless we're loading.
                ZStack {
                    Rectangle()
                        .foregroundColor(loadingViewBackgroundColor)
                        .frame(height: threshold)
                    progress(state)
                }.offset(y: (state == .loading) ? -max(0, offset) : -threshold)
            }
        }
        // Put a fixed PositionIndicator in the background so that we have
        // a reference point to compute the scroll offset.
        .background(PositionIndicator(type: .fixed))
        .background(loadingViewBackgroundColor)
        // Once the scrolling offset changes, we want to see if there should
        // be a state change.
        .onPreferenceChange(PositionPreferenceKey.self) { values in
            // Compute the offset between the moving and fixed PositionIndicators
            let movingY = values.first { $0.type == .moving }?.y ?? 0
            let fixedY = values.first { $0.type == .fixed }?.y ?? 0
            offset = movingY - fixedY
            if state != .loading { // If we're already loading, ignore everything
                // Map the preference change action to the UI thread
                DispatchQueue.main.async {
                    // If the user pulled down below the threshold, prime the view
                    if offset > threshold, state == .waiting {
                        state = .primed

                        // If the view is primed and we've crossed the threshold again on the
                        // way back, trigger the refresh
                    } else if offset < threshold, state == .primed {
                        state = .loading
                        self.pullReleasedFeedbackGenerator.impactOccurred()
                        onRefresh { // trigger the refreshing callback
                            // once refreshing is done, smoothly move the loading view
                            // back to the offset position
                            withAnimation {
                                self.state = .waiting
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Internal

    let showsIndicators: Bool // if the ScrollView should show indicators
    let loadingViewBackgroundColor: Color
    let threshold: CGFloat // what height do you have to pull down to trigger the refresh
    let onRefresh: OnRefresh // the refreshing action
    let progress: RefreshProgressBuilder<Progress> // custom progress view
    let content: () -> Content // the ScrollView content
    // Haptic Feedback
    let pullReleasedFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: Private

    @State
    private var offset: CGFloat = 0
    @State
    private var state = RefreshState.waiting // the current state
}

// Extension that uses default RefreshActivityIndicator so that you don't have to
// specify it every time.
extension RefreshableScrollView where Progress == RefreshActivityIndicator {
    public init(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            showsIndicators: showsIndicators,
            loadingViewBackgroundColor: loadingViewBackgroundColor,
            threshold: threshold,
            onRefresh: onRefresh,
            progress: { state in
                RefreshActivityIndicator(isAnimating: state == .loading) {
                    $0.hidesWhenStopped = false
                }
            },
            content: content
        )
    }
}

// MARK: - RefreshActivityIndicator

// Wraps a UIActivityIndicatorView as a loading spinner that works on all SwiftUI versions.
public struct RefreshActivityIndicator: UIViewRepresentable {
    // MARK: Lifecycle

    public init(isAnimating: Bool, configuration: ((UIView) -> Void)? = nil) {
        self.isAnimating = isAnimating
        if let configuration = configuration {
            self.configuration = configuration
        }
    }

    // MARK: Public

    public typealias UIView = UIActivityIndicatorView

    public var isAnimating: Bool = true
    public var configuration = { (_: UIView) in }

    public func makeUIView(context _: UIViewRepresentableContext<Self>) -> UIView {
        UIView()
    }

    public func updateUIView(_ uiView: UIView, context _: UIViewRepresentableContext<Self>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
        configuration(uiView)
    }
}

#if compiler(>=5.5)
// Allows using RefreshableScrollView with an async block.
@available(iOS 15.0, *)
extension RefreshableScrollView {
    public init(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        action: @escaping @Sendable () async -> Void,
        @ViewBuilder progress: @escaping RefreshProgressBuilder<Progress>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            showsIndicators: showsIndicators,
            loadingViewBackgroundColor: loadingViewBackgroundColor,
            threshold: threshold,
            onRefresh: { refreshComplete in
                Task {
                    await action()
                    refreshComplete()
                }
            },
            progress: progress,
            content: content
        )
    }
}
#endif

// MARK: - RefreshableCompat

public struct RefreshableCompat<Progress>: ViewModifier where Progress: View {
    // MARK: Lifecycle

    public init(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder progress: @escaping RefreshProgressBuilder<Progress>
    ) {
        self.showsIndicators = showsIndicators
        self.loadingViewBackgroundColor = loadingViewBackgroundColor
        self.threshold = threshold
        self.onRefresh = onRefresh
        self.progress = progress
    }

    // MARK: Public

    public func body(content: Content) -> some View {
        RefreshableScrollView(
            showsIndicators: showsIndicators,
            loadingViewBackgroundColor: loadingViewBackgroundColor,
            threshold: threshold,
            onRefresh: onRefresh,
            progress: progress
        ) {
            content
        }
    }

    // MARK: Private

    private let showsIndicators: Bool
    private let loadingViewBackgroundColor: Color
    private let threshold: CGFloat
    private let onRefresh: OnRefresh
    private let progress: RefreshProgressBuilder<Progress>
}

#if compiler(>=5.5)
@available(iOS 15.0, *)
extension List {
    @ViewBuilder
    public func refreshableCompat<Progress: View>(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder progress: @escaping RefreshProgressBuilder<Progress>
    ) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            self.refreshable {
                await withCheckedContinuation { cont in
                    onRefresh {
                        cont.resume()
                    }
                }
            }
        } else {
            modifier(RefreshableCompat(
                showsIndicators: showsIndicators,
                loadingViewBackgroundColor: loadingViewBackgroundColor,
                threshold: threshold,
                onRefresh: onRefresh,
                progress: progress
            ))
        }
    }
}
#endif

extension View {
    @ViewBuilder
    public func refreshableCompat<Progress: View>(
        showsIndicators: Bool = true,
        loadingViewBackgroundColor: Color = defaultLoadingViewBackgroundColor,
        threshold: CGFloat = defaultRefreshThreshold,
        onRefresh: @escaping OnRefresh,
        @ViewBuilder progress: @escaping RefreshProgressBuilder<Progress>
    ) -> some View {
        modifier(RefreshableCompat(
            showsIndicators: showsIndicators,
            loadingViewBackgroundColor: loadingViewBackgroundColor,
            threshold: threshold,
            onRefresh: onRefresh,
            progress: progress
        ))
    }
}

// MARK: - TestView

struct TestView: View {
    // MARK: Internal

    var body: some View {
        RefreshableScrollView(
            onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.now = Date()
                    done()
                }
            }
        ) {
            VStack {
                ForEach(1..<20) {
                    Text("\(Calendar.current.date(byAdding: .hour, value: $0, to: now)!)")
                        .padding(.bottom, 10)
                }
            }.padding()
        }
    }

    // MARK: Private

    @State
    private var now = Date()
}

// MARK: - TestViewWithLargerThreshold

struct TestViewWithLargerThreshold: View {
    // MARK: Internal

    var body: some View {
        RefreshableScrollView(
            threshold: defaultRefreshThreshold * 3,
            onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.now = Date()
                    done()
                }
            }
        ) {
            VStack {
                ForEach(1..<20) {
                    Text("\(Calendar.current.date(byAdding: .hour, value: $0, to: now)!)")
                        .padding(.bottom, 10)
                }
            }.padding()
        }
    }

    // MARK: Private

    @State
    private var now = Date()
}

// MARK: - TestViewWithCustomProgress

struct TestViewWithCustomProgress: View {
    // MARK: Internal

    var body: some View {
        RefreshableScrollView(
            onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.now = Date()
                    done()
                }
            },
            progress: { state in
                if state == .waiting {
                    Text("Pull me down...")
                } else if state == .primed {
                    Text("Now release!")
                } else {
                    Text("Working...")
                }
            }
        ) {
            VStack {
                ForEach(1..<20) {
                    Text("\(Calendar.current.date(byAdding: .hour, value: $0, to: now)!)")
                        .padding(.bottom, 10)
                }
            }.padding()
        }
    }

    // MARK: Private

    @State
    private var now = Date()
}

#if compiler(>=5.5)
@available(iOS 15, *)
struct TestViewWithAsync: View {
    // MARK: Internal

    var body: some View {
        RefreshableScrollView(action: {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            now = Date()
        }, progress: { state in
            RefreshActivityIndicator(isAnimating: state == .loading) {
                $0.hidesWhenStopped = false
            }
        }) {
            VStack {
                ForEach(1..<20) {
                    Text("\(Calendar.current.date(byAdding: .hour, value: $0, to: now)!)")
                        .padding(.bottom, 10)
                }
            }.padding()
        }
    }

    // MARK: Private

    @State
    private var now = Date()
}
#endif

// MARK: - TestViewCompat

struct TestViewCompat: View {
    // MARK: Internal

    var body: some View {
        VStack {
            ForEach(1..<20) {
                Text("\(Calendar.current.date(byAdding: .hour, value: $0, to: now)!)")
                    .padding(.bottom, 10)
            }
        }
        .refreshableCompat(
            showsIndicators: false,
            onRefresh: { done in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.now = Date()
                    done()
                }
            },
            progress: { state in
                RefreshActivityIndicator(isAnimating: state == .loading) {
                    $0.hidesWhenStopped = false
                }
            }
        )
    }

    // MARK: Private

    @State
    private var now = Date()
}

// MARK: - TestView_Previews

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}

// MARK: - TestViewWithLargerThreshold_Previews

struct TestViewWithLargerThreshold_Previews: PreviewProvider {
    static var previews: some View {
        TestViewWithLargerThreshold()
    }
}

// MARK: - TestViewWithCustomProgress_Previews

struct TestViewWithCustomProgress_Previews: PreviewProvider {
    static var previews: some View {
        TestViewWithCustomProgress()
    }
}

#if compiler(>=5.5)
@available(iOS 15, *)
struct TestViewWithAsync_Previews: PreviewProvider {
    static var previews: some View {
        TestViewWithAsync()
    }
}
#endif

// MARK: - TestViewCompat_Previews

struct TestViewCompat_Previews: PreviewProvider {
    static var previews: some View {
        TestViewCompat()
    }
}
