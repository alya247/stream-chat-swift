//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

// `ChatMessageDefaultAttachment` should be removed once changes in UI SDK will be applied.
// Please search for this flag once the default model is removed and apply necessary changes.
let isAttachmentModelSeparationChangesApplied = true

/// A type for default built-in attachment types. Used for both exposing it in `_ChatMessage<ExtraData: ExtraDataTypes>` and
/// sending back to backend if attachment doesn't need prior uploading. (Public sending API is in progress)
public struct ChatMessageDefaultAttachment: ChatMessageAttachment, AttachmentEnvelope, Decodable {
    /// A unique identifier of the attachment.
    public var id: AttachmentId?
    /// When a new attachment is created, this value contains the URL of the source from which the attachment
    /// data are uploaded to the server. For already sent attachments this value is usually `nil`. This value is
    /// device-specific and is not synced with other devices.
    public var localURL: URL?
    /// A local attachment state
    public var localState: LocalAttachmentState?
    /// A title for the attachment.
    public let title: String
    /// An author generated by backend after enriching URL. (e.g `YouTube`)
    public let author: String?
    /// A description text.
    public let text: String?
    /// A type (see `AttachmentType`).
    public let type: AttachmentType
    /// Actions from a command (see `Action`, `Command`).
    public let actions: [AttachmentAction]
    /// A URL. Depends on type of the attachment (e.g. some asset URL, enriched URL, tappable title URL)
    public var url: URL?
    /// An image URL.
    public var imageURL: URL?
    /// An image preview URL.
    public let imagePreviewURL: URL?
    /// A file description (see `AttachmentFile`).
    public let file: AttachmentFile?

    init(
        id: AttachmentId,
        type: AttachmentType,
        localURL: URL?,
        localState: LocalAttachmentState?,
        title: String,
        file: AttachmentFile? = nil
    ) {
        self.id = id
        self.type = type
        self.localState = localState
        self.localURL = localURL
        self.title = title
        self.file = file
        author = nil
        text = nil
        actions = []
        imagePreviewURL = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        let author = try container.decodeIfPresent(String.self, forKey: .author)
        self.author = author
        text = try container.decodeIfPresent(String.self, forKey: .text)?.trimmingCharacters(in: .whitespacesAndNewlines)

        title = (
            try container.decodeIfPresent(String.self, forKey: .title)
                ?? container.decodeIfPresent(String.self, forKey: .fallback)
                ?? container.decodeIfPresent(String.self, forKey: .name)
                ?? ""
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // Parse imageURL.
        imageURL = (
            try container.decodeIfPresent(String.self, forKey: .image)
                ?? container.decodeIfPresent(String.self, forKey: .imageURL)
                ?? container.decodeIfPresent(String.self, forKey: .thumbURL)
        )?.attachmentFixedURL

        imagePreviewURL = try container.decodeIfPresent(String.self, forKey: .thumbURL)?.attachmentFixedURL

        // Parse URL.
        url = (
            try container.decodeIfPresent(String.self, forKey: .assetURL)
                ?? container.decodeIfPresent(String.self, forKey: .url)
                ?? container.decodeIfPresent(String.self, forKey: .titleLink)
                ?? container.decodeIfPresent(String.self, forKey: .ogURL)
        )?.attachmentFixedURL

        let type: AttachmentType
        let itWasLinkOriginally = container.contains(.ogURL)
        if itWasLinkOriginally {
            type = .link(try? container.decode(String.self, forKey: .type))
        } else {
            type = AttachmentType(rawValue: try container.decode(String.self, forKey: .type))
        }
        // compiler is confused by expression unless we use helper variable for type
        self.type = type

        file = (type == .file || type == .video) ? try AttachmentFile(from: decoder) : nil
        actions = try container.decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AttachmentCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(title, forKey: (type == .image ? .fallback : .title))
        try container.encodeIfPresent(url, forKey: .assetURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try file?.encode(to: encoder)
    }
}
