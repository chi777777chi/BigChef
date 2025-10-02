//
//  AuthHeaderView.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import SwiftUI

struct AuthHeaderView: View {
    let title1: String
    let title2: String
    
    var body: some View {
        VStack(alignment: .center) {
            HStack { Spacer()}
            
            Text(title1)
                .font(.largeTitle)
                .fontWeight(.semibold)
            
            Text(title2)
                .font(.largeTitle)
                .fontWeight(.semibold)
        }
        .frame(height: 260)
        .padding(.leading)
        .background(Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedShape(corners: [.bottomLeft, .bottomRight]))
    }
}

struct AuthHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AuthHeaderView(title1: "Hello", title2: "Welcome back")
    }
}
