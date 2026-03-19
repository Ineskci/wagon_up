# app/services/pdf_parser.rb
require 'pdf-reader'

class PdfParser
  MAX_CHARS = 12_000

  def self.extract(file)
    new(file).extract
  end

  def initialize(file)
    @file = file
  end

  def extract
    path = active_storage_path(@file)
    text = read_pdf(path)
    raise PdfParserError, "PDF vazio ou ilegível" if text.blank?
    text.strip.truncate(MAX_CHARS, omission: "... [truncado]")
  rescue PDF::Reader::MalformedPDFError
    raise PdfParserError, "PDF corrompido ou inválido"
  end

  private

  def active_storage_path(file)
    ActiveStorage::Blob.service.path_for(file.blob.key).to_s
  end

  def read_pdf(path)
    reader = PDF::Reader.new(path)
    reader.pages.map(&:text).join("\n")
  end
end

class PdfParserError < StandardError; end
