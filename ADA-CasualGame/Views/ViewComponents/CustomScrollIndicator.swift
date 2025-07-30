import SwiftUI

// MARK: - Modifier and Indicator
// ----------------------------------

// The modifier now accepts a positionXoffset.
struct CustomScrollIndicatorModifier: ViewModifier {
    @Binding var scrollOffset: CGFloat
    @Binding var contentHeight: CGFloat
    let positionXoffset: CGFloat // The new property

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                content
                
                // Pass the offset to the indicator view.
                CustomScrollIndicator(
                    contentHeight: contentHeight,
                    scrollOffset: scrollOffset,
                    viewHeight: geometry.size.height,
                    positionXoffset: positionXoffset
                )
            }
        }
    }
}

// The indicator view now uses the offset.
struct CustomScrollIndicator: View {
    let contentHeight: CGFloat
    let scrollOffset: CGFloat
    let viewHeight: CGFloat
    let positionXoffset: CGFloat // The new property

    private let indicatorThumbHeight: CGFloat = 80.0

    var body: some View {
        if contentHeight > viewHeight {
            ZStack(alignment: .top) {
                Image("scroll_background")
                    .resizable()

                Image("scroll_indicator")
                    .resizable()
                    .frame(height: indicatorThumbHeight)
                    .offset(y: indicatorOffset)
            }
            .frame(width: 10)
            .padding(.trailing, 4)
            .offset(x: positionXoffset) // ✅ The new offset is applied here.
        }
    }

    private var indicatorOffset: CGFloat {
        guard contentHeight > viewHeight, viewHeight > indicatorThumbHeight else { return 0 }
        
        let scrollableDistance = contentHeight - viewHeight
        let indicatorTravelDistance = viewHeight - indicatorThumbHeight
        
        let calculatedOffset = (scrollOffset / scrollableDistance) * indicatorTravelDistance
        
        return min(max(0, calculatedOffset), indicatorTravelDistance)
    }
}

// MARK: - View Extension
// ----------------------------------

extension View {
    // The helper function now accepts the new offset parameter.
    func customScrollIndicator(
        scrollOffset: Binding<CGFloat>,
        contentHeight: Binding<CGFloat>,
        positionXoffset: CGFloat = 0 // Default value is 0
    ) -> some View {
        self.modifier(
            CustomScrollIndicatorModifier(
                scrollOffset: scrollOffset,
                contentHeight: contentHeight,
                positionXoffset: positionXoffset
            )
        )
    }
}

// MARK: - Preview
// ----------------------------------

#Preview {
    struct PreviewWrapper: View {
        @State private var scrollOffset: CGFloat = 0
        @State private var contentHeight: CGFloat = 0

        var body: some View {
            VStack {
                Text("My Scrollable List")
                    .font(.largeTitle)
                    .padding()
                
                ScrollView {
                    VStack {
                        ForEach(1...40, id: \.self) { i in
                            Text("Item \(i)")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .background(
                        GeometryReader { contentProxy in
                            Color.clear
                                .onAppear {
                                    self.contentHeight = contentProxy.size.height
                                }
                        }
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onChange(of: proxy.frame(in: .named("scroll")).minY) { _, newMinY in
                                    self.scrollOffset = -newMinY
                                }
                        }
                    )
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: "scroll")
                // ✅ Example of using the new offset parameter in the modifier call.
                .customScrollIndicator(
                    scrollOffset: $scrollOffset,
                    contentHeight: $contentHeight,
                    positionXoffset: -10 // Moves the bar 10 points to the left
                )
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
}
