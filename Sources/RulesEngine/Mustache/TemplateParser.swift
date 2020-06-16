//
//  Parser.swift
//  Swift-Rules
//
//  Created by Jiabin Geng on 5/18/20.
//  Copyright © 2020 Adobe. All rights reserved.
//

import Foundation

public class TemplateParser {
    fileprivate let tagDelimiterPair: DelimiterPair

    init(tagDelimiterPair: DelimiterPair = ("{{", "}}")) {
        self.tagDelimiterPair = tagDelimiterPair
    }

    public func parse(_ templateString: String) -> Result<[TemplateToken], Error> {
        var tokens: [TemplateToken] = []
        let currentDelimiters = ParserTagDelimiters(tagDelimiterPair: tagDelimiterPair)

        var state: State = .start
        var i = templateString.startIndex
        let end = templateString.endIndex

        while i < end {
            switch state {
            case .start:
                if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    state = .tag(startIndex: i)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                } else {
                    state = .text(startIndex: i)
                }
            case .text(let startIndex):
                if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    if startIndex != i {
                        let range = startIndex..<i
                        let token = TemplateToken(
                            type: .text(String(templateString[range])),

                            templateString: templateString,
                            range: startIndex..<i)
                        tokens.append(token)
                    }
                    state = .tag(startIndex: i)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                }
            case .tag(let startIndex):
                if index(i, isAt: currentDelimiters.tagDelimiterPair.1, in: templateString) {
                    let tagInitialIndex = templateString.index(startIndex, offsetBy: currentDelimiters.tagStartLength)
                    let tokenRange = startIndex..<templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    let content = String(templateString[tagInitialIndex..<i])
                    let mustacheToken: MustacheToken? = try? TokenParser.parse(content).get()

                    let token = TemplateToken(
                        type: .mustache(mustacheToken),
                        templateString: templateString,
                        range: tokenRange)
                    tokens.append(token)

                    state = .start
                    i = templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    i = templateString.index(before: i)
                }
                break
            }

            i = templateString.index(after: i)
        }

        switch state {
        case .start:
            break
        case .text(let startIndex):
            let range = startIndex..<end
            let token = TemplateToken(
                type: .text(String(templateString[range])),

                templateString: templateString,
                range: range)
            tokens.append(token)
        case .tag:
            let error = MustacheError(message: "Unclosed Mustache tag")
            return .failure(error)
        }
        return .success(tokens)
    }
    private func index(_ index: String.Index, isAt string: String?, in templateString: String) -> Bool {
        guard let string = string else {
            return false
        }
        return templateString[index...].hasPrefix(string)
    }
    // MARK: - Private

    fileprivate enum State {
        case start
        case text(startIndex: String.Index)
        case tag(startIndex: String.Index)
    }

    fileprivate struct ParserTagDelimiters {
        let tagDelimiterPair: DelimiterPair
        let tagStartLength: Int
        let tagEndLength: Int

        init(tagDelimiterPair: DelimiterPair) {
            self.tagDelimiterPair = tagDelimiterPair

            tagStartLength = tagDelimiterPair.0.distance(from: tagDelimiterPair.0.startIndex, to: tagDelimiterPair.0.endIndex)
            tagEndLength = tagDelimiterPair.1.distance(from: tagDelimiterPair.1.startIndex, to: tagDelimiterPair.1.endIndex)

        }
    }

}