//
//  ReactNativeDemoView.swift
//  FRW
//
//  Created by Claude on 2025-07-06.
//

import SwiftUI

struct ReactNativeDemoView: View {
    @State private var showReactNativeView = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("React Native Integration Demo")
                .font(.title)
                .padding()
            
            Text("This demonstrates how to load a React Native view from iOS native code")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                showReactNativeView = true
            }) {
                Text("Open React Native View")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showReactNativeView) {
            ReactNativeView()
        }
    }
}

// MARK: - Preview

struct ReactNativeDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ReactNativeDemoView()
    }
}