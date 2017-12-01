// =========================================================================================
// Copyright 2017 Gal Orlanczyk
//
// Permission is hereby granted, free of charge,
// to any person obtaining a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// =========================================================================================

import Foundation

/*
 Base tags used as abstract classes to implement all tag types.
 */

/************************************************************/
// MARK: - BaseTag
/************************************************************/

public class BaseTag: Tag {
    public class var tag: String { fatalError("Abstract class make sure to implement tag in subclass") }
    
    public let text: String
    public let tagDataText: String
    public let tagType: Tag.Type
    
    public required init(text: String, tagType: Tag.Type, extraParams: [String: Any]?) throws {
        self.text = text
        self.tagDataText = text.getTagValue(forType: tagType)
        self.tagType = tagType
    }
}

/************************************************************/
// MARK: - StringInitializable
/************************************************************/

public protocol StringInitializable {
    init?(_ string: String)
}

extension Int: StringInitializable {}
extension Double: StringInitializable {}

/************************************************************/
// MARK: - BaseValueTag
/************************************************************/

public class BaseValueTag<T: StringInitializable>: Tag {
    public class var tag: String { fatalError("Abstract implementation make sure to implement tag in subclass") }
    
    public let text: String
    public let tagDataText: String
    public let tagType: Tag.Type
    public let value: T

    public required init(text: String, tagType: Tag.Type, extraParams: [String: Any]?) throws {
        let baseTag = try BaseTag(text: text, tagType: tagType, extraParams: nil) // Base Tag has no extra params so send nil
        self.text = baseTag.text
        self.tagDataText = baseTag.tagDataText
        self.tagType = baseTag.tagType
        if let value = T(self.tagDataText) {
            self.value = value
        } else {
            throw TagError.invalidData(tag: tagType.tag, received: "\(self.tagDataText)", expected: "\(String(describing: T.self))")
        }
    }
}

/************************************************************/
// MARK: - BaseAttributedTag
/************************************************************/

public class BaseAttributedTag: AttributedTag {
    public class var tag: String { fatalError("Abstract implementation make sure to implement tag in subclass") }
    
    public let text: String
    public let tagDataText: String
    public let tagType: Tag.Type
    public let attributes: [String: String]
    
    public required init(text: String, tagType: Tag.Type, extraParams: [String: Any]?) throws {
        let baseTag = try BaseTag.init(text: text, tagType: tagType, extraParams: nil) // Base Tag has no extra params so send nil
        self.text = baseTag.text
        self.tagDataText = baseTag.tagDataText
        self.tagType = baseTag.tagType
        // Use extra params to get the required attributes
        guard let seperator = extraParams?[TagParamsKeys.attributesSeperator] as? String,
            let attributesCount = extraParams?[TagParamsKeys.attributesCount] as? Int,
            let attributeKeys = extraParams?[TagParamsKeys.attributesKeys] as? [String]
            else { fatalError("missing params, make sure to send all needed params") }
        let extrasToRemove = extraParams?[TagParamsKeys.attributesExtrasToRemove] as? [String] // optional params
        guard let attributedTagType = tagType as? AttributedTag.Type else { fatalError("tag type must be of type: AttributedTag") }
        self.attributes = attributedTagType.getAttributes(from: self.tagDataText, seperatedBy: seperator, extrasToRemove: extrasToRemove)
        if attributes.count == 0 {
            throw TagError.invalidData(tag: tagType.tag, received: "received 0 attributes", expected: "expected to receive \(attributesCount) attributes")
        }
        try self.validateIntegrity(requiredAttributes: attributeKeys)
    }
}
