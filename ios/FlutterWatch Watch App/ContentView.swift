//
//  ContentView.swift
//  FlutterWatch Watch App
//
//  Created by Koichi Kishimoto on 2025/08/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: WCSessionManager

    var body: some View {
        VStack(spacing: 15) {
            Text("Watch")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(sessionManager.counter)")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.blue)

            HStack(spacing: 20) {
                Button {
                    sessionManager.decrementCounter()
                } label: {
                    Image(systemName: "minus")
                }
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(Color.red)
                .cornerRadius(17.5)

                Button {
                    sessionManager.incrementCounter()
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundColor(.white)
                .frame(width: 35, height: 35)
                .background(Color.blue)
                .cornerRadius(17.5)
            }

            HStack {
                Circle()
                    .fill(sessionManager.isConnected ? Color.green : Color.red)
                    .frame(width: 6, height: 6)

                Text(sessionManager.isConnected ? "接続完了" : "未接続")
                    .font(.caption2)
                    .foregroundColor(sessionManager.isConnected ? .green : .red)
            }
        }
        .padding()
        .onAppear {
            sessionManager.startSession()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WCSessionManager())
}
