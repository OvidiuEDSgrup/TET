create procedure CreeazaDiezPersonal @numeTabela varchar(100)
AS
--	tabela utilizata in procedurile pentru calcul salar de baza (pornind de la salar de incadrare cu sporuri cu caracter permament setate sa intre in salarul de baza
if @numeTabela='#personalSalBaza'
Begin
	alter table #personalSalBaza
	add salar_de_incadrare float not null, salar_de_baza float not null,
		indemnizatia_de_conducere float not null, spor_specific float not null, 
		spor_conditii_1 float not null, spor_conditii_2 float not null, spor_conditii_3 float not null, 
		spor_conditii_4 float not null, spor_conditii_5 float not null, spor_conditii_6 float not null
end
