--***  
/* Inchide comanda, tratand flag pentru comenzi speciale */
CREATE procedure [dbo].wmInchidComanda @sesiune varchar(50), @parXML xml  
as 
if exists(select * from sysobjects where name='wmInchidComandaSP' and type='P')
begin
	exec wmInchidComandaSP @sesiune=@sesiune, @parXML=@parXML 
	return 0
end

	declare 
		@comanda varchar(20),@definitivare xml, @gestiuneDepozitBK varchar(20), @utilizator varchar(100), @inDepozit bit

	set @inDepozit = ISNULL(@parXML.value('(/*/@inDepozit)[1]','bit'),0)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	SELECT 
		@gestiuneDepozitBK= dbo.wfProprietateUtilizator('GESTDEPBK',@utilizator),
		@comanda=rtrim(@parXML.value('(/row/@comanda)[1]','varchar(20)'))

	if @inDepozit=1
		update Contracte set gestiune=@gestiuneDepozitBK where idContract=@comanda

	set @definitivare=
		(
			select @comanda idContract for xml RAW
		)

	exec wOPDefinitivareContract @sesiune=@sesiune, @parXML=@definitivare

select 'back(1)' actiune
for xml raw, root('Mesaje')
