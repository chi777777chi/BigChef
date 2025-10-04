//
//  UserStatsView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import SwiftUI

struct UserStatsView: View {
    var body: some View {
        HStack(spacing: 24) {
            HStack(spacing: 4) {
                Text("2")
                    .font(.subheadline).bold()
                Text("Following")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            HStack {
                Text("1.2M")
                    .font(.subheadline).bold()
                Text("Followers")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct UserStatsView_Previews: PreviewProvider {
    static var previews: some View {
        UserStatsView()
    }
}
