create procedure CreazaDiezTerti @numeTabela varchar(50)
AS
begin	
	if 	@numeTabela='#tertiVies'
		alter table #tertiVies
		add tara varchar(20), cod_fiscal varchar(20), valid varchar(50), requestIdentifier varchar(50)
end
