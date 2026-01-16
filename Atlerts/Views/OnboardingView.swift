//
//  OnboardingView.swift
//  Atlerts
//
//  Created by Gabriel Rosales Montes on 12/01/26.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingView: View {
    // Saves to memory if the user has seen the tutorial
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var currentPage = 0
    
    // 🔥 DATA TRANSLATED TO ENGLISH
    let pages: [OnboardingPage] = [
        // 1. Welcome
        OnboardingPage(
            image: "bell.badge.fill",
            title: "Welcome to Atlerts",
            description: "Stay informed about the most important company news and receive notifications instantly.",
            color: .blue
        ),
        // 2. Security
        OnboardingPage(
            image: "lock.shield.fill",
            title: "Total Security",
            description: "Your chats and documents are protected. Access securely with FaceID.",
            color: .green
        ),
        // 3. Documents
        OnboardingPage(
            image: "doc.text.viewfinder",
            title: "Digital Library",
            description: "Access manuals, regulations, and important PDF files directly within the App.",
            color: .orange
        ),
        // 4. Training
        OnboardingPage(
            image: "play.laptopcomputer",
            title: "Training Center",
            description: "Upskill by watching exclusive videos and courses to improve your abilities.",
            color: .purple
        ),
        // 5. Calendar
        OnboardingPage(
            image: "calendar.badge.clock",
            title: "Event Calendar",
            description: "Sync your schedule and never miss a meeting or corporate event.",
            color: .red
        ),
        // 6. Forms
        OnboardingPage(
            image: "list.clipboard.fill",
            title: "Dynamic Forms",
            description: "Respond to surveys, reports, and requests quickly and easily.",
            color: .teal
        )
    ]
    
    var body: some View {
        ZStack {
            // Dynamic background gradient based on page color
            LinearGradient(gradient: Gradient(colors: [pages[currentPage].color.opacity(0.1), .white]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                // 1. CAROUSEL
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            // Large Icon with Shadow
                            Image(systemName: pages[index].image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 140)
                                .foregroundColor(pages[index].color)
                                .padding(.bottom, 20)
                                .shadow(color: pages[index].color.opacity(0.3), radius: 10, x: 0, y: 10)
                            
                            // Title
                            Text(pages[index].title)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Description
                            Text(pages[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // 2. DOTS INDICATORS
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // 3. ACTION BUTTON (Next / Get Started)
                Button(action: {
                    if currentPage < pages.count - 1 {
                        // Advance
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // Finish
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                }) {
                    // TRANSLATED BUTTON LABELS
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pages[currentPage].color)
                        .cornerRadius(15)
                        .shadow(color: pages[currentPage].color.opacity(0.4), radius: 8, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .transition(.opacity)
    }
}
