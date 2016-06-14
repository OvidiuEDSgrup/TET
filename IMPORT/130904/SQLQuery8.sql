if ''<>''
	exec yso_xStergTabela @tabela='pozcon', @sursaImport='\\10.0.0.10\import\ASIS_contracte_furnizori_import 13 august 2013.xlsx'
else
begin 
	delete pozcon where tip='FA'
	delete con where tip='FA'
end	
go
exec yso_xScriuTabela @tabela='pozcon', @sursaImport='\\10.0.0.10\import\ASIS_contracte_furnizori_import 13 august 2013.xlsx'
go
select * from mesajeASiS m where m.Destinatar=HOST_ID()