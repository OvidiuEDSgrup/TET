create procedure CreeazaDiezDiurne @numeTabela varchar(100)
AS
--	tabela utilizata in procedurile pentru rapoarte (rapDiurne) si citire diurne (wIaDiurne)
if @numeTabela='#Diurne'
Begin
	alter table #Diurne
	add loc_de_munca varchar(9), cod_functie varchar(6), 
		data_inceput datetime, data_sfarsit datetime, zile float, tara varchar(20), valuta varchar(20), tip_diurna varchar(1), curs float, 
		diurna_zi decimal(12), diurna_neimpozabila_zi decimal(12), diurna decimal(12,2), diurna_neimpozabila decimal(12,2), diurna_impozabila decimal(12,2), 
		diurna_lei decimal(12,2), diurna_neimpozabila_lei decimal(12,2), diurna_impozabila_lei decimal(12,2), idDiurna int
end
