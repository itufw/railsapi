class AbnSearch
  include HTTParty
  base_uri 'https://abr.business.gov.au/abrxmlsearch'

  def initialize
    @query = { query: {'authenticationGuid': Rails.application.secrets.abn_guid, 'includeHistoricalDetails': 'N' } }
  end

  def search_by_abn(abn)
    @query[:query]['searchString'] = abn
    return self.class.get('/AbrXmlSearch.asmx/SearchByASICv201408', @query) if abn.length==9
    self.class.get('/AbrXmlSearch.asmx/SearchByABNv201408', @query)
  end

end
