if @fisier<>''
	exec yso_xStergTabela @tabela='pozcon', @sursaImport=@fisier
else
begin 
	delete pozcon where tip='BF'
	delete con where tip='BF'
end