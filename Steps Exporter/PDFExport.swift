//
//  PDFExport.swift
//  Steps Exporter
//
//  Created by rillo on 15.11.25.
//

import PDFKit
import Down

let loremIpsum = """
    # Lorem Ipsum
    Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.  

    Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.  

    Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat. Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.  

    Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming id quod mazim placerat facer possim assum. Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat. Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper suscipit lobortis nisl ut aliquip ex ea commodo consequat.  

    Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie consequat, vel illum dolore eu feugiat nulla facilisis.   

    At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, At accusam aliquyam diam diam dolore dolores duo eirmod eos erat, et nonumy sed tempor et et invidunt justo labore Stet clita ea et gubergren, kasd magna no rebum. sanctus sea sed takimata ut vero voluptua. est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam
    """

typealias StepData = (Date, Double)

func createFancyPDF(with: [StepData]) async throws -> Data {
    //let markdown = "# Hello World!"
    let markdown = loremIpsum
    let html = try Down(markdownString: markdown).toHTML()
    
    let pageWidth: CGFloat = 595.2
    let pageHeight: CGFloat = 841.8
    let margin: CGFloat = 40
    
    
    return await htmlToPDF(html)!
}

func createPDF(with data: [StepData]) -> Data {
    let pdfMetaData = [
        kCGPDFContextCreator: "Steps Exporter",
        kCGPDFContextAuthor: "Rillonautikum",
        kCGPDFContextTitle: "Steps Export"
    ]
    
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]
    
    let pageWidth = 595.2
    let pageHeight = 841.8
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
    
    let dataPDF = renderer.pdfData { (context) in
        context.beginPage()
        var yPosition: CGFloat = 20
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        
        for (date, steps) in data {
            let line = "\(date): \(Int(steps)) Schritte\n"
            line.draw(at: CGPoint(x: 20, y: yPosition), withAttributes: attributes)
            yPosition += 20
            
            if yPosition > pageHeight - 40 {
                context.beginPage()
                yPosition = 20
            }
        }
    }
    return dataPDF
}

// MARK: - PDFView

import SwiftUI
struct PDFViewCustom: UIViewRepresentable {
    var pdfData: PDFDocument
    
    init(showing data: Data) throws {
            self.pdfData = PDFDocument(data: data)!
        }

        //you could also have inits that take a URL or Data

        func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = pdfData
            pdfView.autoScales = true
            return pdfView
        }

        func updateUIView(_ pdfView: PDFView, context: Context) {
            pdfView.document = pdfData
        }
}

// MARK: - HTML to PDF
import WebKit

func htmlToPDF(_ html: String) async -> Data? {
    return await withCheckedContinuation { cont in
        let webView = WKWebView(frame: .zero)
        
        let delegate = WebViewPDFDelegate(webView: webView) { data in
            cont.resume(returning: data)
        }
        
        // keep webview alive
        objc_setAssociatedObject(
            webView,
            "delegate",
            delegate,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        
        webView.loadHTMLString(html, baseURL: nil)
    }
}

class WebViewPDFDelegate: NSObject, WKNavigationDelegate {
    let onFinish: (Data?) -> Void
    var webView: WKWebView?
    
    init(webView: WKWebView, onFinish: @escaping (Data?) -> Void) {
        self.webView = webView
        self.onFinish = onFinish
        super.init()
        webView.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //let config = WKPDFConfiguration(rect: )
        let config = WKPDFConfiguration()
        config.rect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        
        webView.createPDF(configuration: config) { result in
            switch result {
            case .success(let data):
                self.onFinish(data)
            case .failure:
                self.onFinish(nil)
            }
        }
    }
}
