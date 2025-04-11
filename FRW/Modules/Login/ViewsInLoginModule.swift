//
//  ViewsInLoginModule.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import SwiftUI

// MARK: - ImportTitleHeader

struct ImportTitleHeader: View {
    var backupType: RestoreWalletViewModel.ImportType

    var body: some View {
        VStack(spacing: 16) {
            Image(backupType.icon40)
                .resizable()
                .frame(width: 64, height: 64)
            Text(backupType.title)
                .font(.inter(size: 20, weight: .bold))
                .foregroundStyle(Color.Theme.Text.black)
                .frame(height: 32)
        }
    }
}

// MARK: - ImportSectionTitleView

struct ImportSectionTitleView: View {
    let title: String
    let isStar: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.inter(size: 14, weight: .bold))
                .foregroundStyle(Color.Theme.Text.black)
            if isStar {
                Text(" *")
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.Accent.red)
            }
            Spacer()
        }
    }
}

// MARK: - ImportTextView

struct ImportTextView: View {
    @Binding
    var content: String
    var placeholder: String? = ""
    var isFirstResponder: Bool = false
    var textDidChange: (String) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text(placeholder ?? "")
                    .font(.inter(size: 14))
                    .foregroundColor(.LL.note)
                    .padding(.top, 8)
            }
            TextEditor(text: $content)
                .introspectTextView { view in
                    if isFirstResponder {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            view.becomeFirstResponder()
                        }
                    }
                    view.tintColor = Color.LL.orange.toUIColor()
                    view.backgroundColor = .clear
                }
                .keyboardType(.alphabet)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: content, perform: { value in
                    textDidChange(value)
                })
                .textEditorBackground(.clear)
                .font(.inter(size: 14))
                .instabug_privateView()
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(.Theme.Background.bg2)
        }
    }
}

// MARK: - AnimatedSecureTextField

public struct AnimatedSecureTextField: View {
    // MARK: Lifecycle

    public init(
        placeholder: String,
        text: Binding<String>,
        textDidChange: @escaping (String) -> Void
    ) {
        self.placeholder = placeholder
        _text = text
        self.textDidChange = textDidChange
        field = .password
    }

    // MARK: Public

    public let placeholder: String

    public var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                HStack {
                    Text(placeholder)
                        .font(.inter(size: 14))
                        .foregroundStyle(Color.Theme.Text.black3)
                    Spacer()
                }
                //            .padding(.horizontal, 16.0)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        field = .password
                    }
                }
            }

            if isSecure {
                SecureField("", text: $text)
                    .disableAutocorrection(true)
                    .foregroundStyle(Color.Theme.Text.black)
                    .autocapitalization(.none)
                    .frame(maxWidth: .infinity)
                    .focused($field, equals: .password)
                    .font(.inter(size: 14))
                    .contentShape(Rectangle())
                    .onChange(of: text) { text in
                        textDidChange(text)
                    }

            } else {
                TextField("", text: $text)
                    .disableAutocorrection(true)
                    .foregroundStyle(Color.Theme.Text.black)
                    .autocapitalization(.none)
                    .frame(maxWidth: .infinity)
                    .focused($field, equals: .password)
                    .font(.inter(size: 14))
                    .contentShape(Rectangle())
                    .onChange(of: text) { text in
                        textDidChange(text)
                    }
                    .instabug_privateView()
            }

            HStack {
                Spacer()

                if !text.isEmpty {
                    Button {
                        isSecure.toggle()
                    } label: {
                        if isSecure {
                            Image(systemName: "eye")
                                .resizable()
                                .foregroundStyle(Color.Theme.Text.black)
                                .frame(width: 20, height: 12)
                        } else {
                            Image(systemName: "eye.slash")
                                .resizable()
                                .foregroundStyle(Color.Theme.Text.black)
                                .frame(width: 20, height: 12)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background {
            RoundedRectangle(cornerRadius: 16.0)
                .foregroundColor(.Theme.Background.bg2)
        }
    }

    // MARK: Internal

    @State
    var isSecure = false
    @Binding
    var text: String

    var textDidChange: (String) -> Void

    // MARK: Private

    private enum FocusedField: Int, Hashable {
        case password
    }

    @FocusState
    private var field: FocusedField?
}

#Preview("1") {
    ImportTitleHeader(backupType: .keyStore)
}

#Preview("2") {
    ImportSectionTitleView(title: "JSON", isStar: true)
}

#Preview("3") {
    ImportTextView(content: .constant(""), placeholder: "abc") { _ in
    }
}

#Preview("4") {
    struct AnimatedSecureTextFieldPreview: View {
        @State
        private var text = ""
        var body: some View {
            AnimatedSecureTextField(placeholder: "abc", text: $text) { _ in
            }
        }
    }

    return AnimatedSecureTextFieldPreview()
}
