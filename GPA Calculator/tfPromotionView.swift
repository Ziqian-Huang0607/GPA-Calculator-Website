//
//  tfPromotionView.swift
//  GPA Calculator
//
//  Created by LegitMichel777 on 2021/5/24.
//

import SwiftUI

struct tfPromotionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing:10) {
            Text("Take a Break")
                .font(.system(size: 28,weight: .semibold,design: .default))
            VStack(alignment: .leading, spacing:0) {
                HStack(spacing:13) {
                    Image("TFIcon")
                        .resizable()
                        .frame(width: 64, height: 64, alignment: .center)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0.0, y: 0.0)
                    VStack(alignment:.leading,spacing:2) {
                        Text("24 Points")
                            .font(.system(size: 22, weight: .semibold, design: .default))
                        Text("A classic card game reimagined")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                    }
                }.padding(12)
                Text("Take a break and play 24 Points, a puzzle card game where players try to use four integers to get the number 24.")
                    .padding(.horizontal,16)
                    .font(.system(size: 17, weight: .medium, design: .default))
                    .padding(.bottom,22)
                HStack(spacing:0) {
                    Spacer()
                    if #available(iOS 14.0, *) {
                        #if targetEnvironment(macCatalyst)
                        Text("App not available on macOS")
                            .font(.system(size: 18, weight: .medium, design: .default))
                        #else
                        Link(destination: URL(string: "https://apps.apple.com/cn/app/24-points-by-michel/id1555800877?l=en")!, label: {
                            Text("View on the App Store")
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(.white)
                                .padding(.horizontal,29)
                                .padding(.vertical,12)
                                .background(Color.blue)
                                .cornerRadius(12, antialiased: true)
                        })
                        #endif
                    } else {
                        Text("App not available on iOS 13")
                            .font(.system(size: 18, weight: .medium, design: .default))
                    }
                    Spacer()
                }.padding(.bottom,15.4)
                    
            }.background(Color.init("promotionFloat"))
            .cornerRadius(22)
        }.padding(.bottom,15)
        .padding(.top,10)
    }
}

struct tfPromotionView_Previews: PreviewProvider {
    static var previews: some View {
        tfPromotionView()
            .padding(.horizontal,17)
    }
}
