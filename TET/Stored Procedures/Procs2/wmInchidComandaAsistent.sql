

CREATE procedure wmInchidComandaAsistent @sesiune varchar(50), @parXML xml  
as 
	declare 
		@comanda varchar(20),@definitivare xml, @utilizator varchar(100), @tert_general varchar(20), @explicatii varchar(200)


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output

	set @comanda=rtrim(@parXML.value('(/row/@comanda)[1]','varchar(20)'))
	set @explicatii=rtrim(@parXML.value('(/row/@explicatii)[1]','varchar(200)'))

	update Contracte set explicatii=@explicatii where idContract=@comanda and ISNULL(@explicatii,'')<>''
	
	if exists(select 1 from JurnalContracte jc where jc.idContract=@comanda and jc.stare=1)
		return

	set @definitivare=
		(
			select @comanda idContract for xml RAW
		)
	exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@definitivare

	declare @tert_gen varchar(20),@actiune varchar(20)
	SELECT top 1 @tert_gen=Val_alfanumerica
		from par where Tip_parametru='UC' and Parametru='TERTGEN'

select  1 as '_home'
for xml raw, root('Mesaje')
