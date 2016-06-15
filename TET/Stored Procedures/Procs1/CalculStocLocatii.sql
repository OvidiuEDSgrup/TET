
CREATE PROCEDURE CalculStocLocatii @sesiune VARCHAR(50), @parXML XML
as
BEGIN
	declare 
		@utilizator varchar(100), @maiMergem bit =1 


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF OBJECT_ID('tmpStocPeLocatii') IS NULL
			create table tmpStocPeLocatii (cod_locatie varchar(20),cod_parinte varchar(20),  stoc float)
	
	truncate table tmpStocPeLocatii

	insert into tmpStocPeLocatii(cod_locatie,cod_parinte,stoc)
	select
		l.cod_locatie cod_locatie,max(l.cod_grup), sum(st.stoc) stoc
	from Locatii L
	INNER JOIN STOCURI st on st.subunitate='1' and st.tip_gestiune='C' and st.cod_gestiune=l.cod_gestiune and l.cod_locatie=st.locatie and st.locatie<>''	
	group by l.cod_locatie

	while @maiMergem=1
	begin
		insert into tmpStocPeLocatii(cod_locatie,cod_parinte,stoc)
		select
			l.Cod_locatie, max(l.cod_grup), sum(t.stoc)
		from Locatii l 
		JOIN tmpStocPeLocatii t on l.Cod_locatie=t.cod_parinte
		LEFT JOIN tmpStocPeLocatii exista on exista.Cod_locatie=t.cod_parinte
		where exista.cod_locatie IS NULL
		group by l.Cod_locatie

		set @maiMergem=@@ROWCOUNT
	end
END
