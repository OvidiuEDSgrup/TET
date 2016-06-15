
CREATE function wfTipProgramareOrePontaj (@sesiune VARCHAR(50), @parXML XML)
returns @tipprogramare table (Tip varchar(20), denumire VARCHAR(50))
/*
	@tip=TP -> tip programare
	@tip=OP -> tip ore pontaj
*/
begin
	declare @tip varchar(2)
	set @tip = @parXML.value('(/*/@tip)[1]', 'varchar(50)')

	if @tip='TP'
		insert into @tipprogramare 
		select 'Schimb1', 'Schimb1'
		union all
		select 'Schimb2', 'Schimb2'
		union all
		select 'Schimb3', 'Schimb3'
		union all
		select 'Tura', 'Tura'
		union all
		select 'Tesa', 'Tesa'
		union all
		select 'Suplimentare', 'Suplimentare'
		union all
		select 'Flexibil', 'Flexibil'
		union all
		select 'Noapte', 'Noapte'
		union all 
		select 'Libere platite', 'Libere platite'
		union all 
		select 'Invoiri', 'Invoiri'
	else
		insert into @tipprogramare 
		select 'ORG', 'Ore regie'
		union all
		select 'OAC', 'Ore acord'
		union all
		select 'OS1', 'Ore suplimentare 1'
		union all
		select 'OS2', 'Ore suplimentare 1'
		union all
		select 'OS3', 'Ore suplimentare 3'
		union all
		select 'OS4', 'Ore suplimentare 4'
		union all
		select 'OCM', 'Ore concediu medical'
		union all
		select 'OCO', 'Ore concediu de odihna'
		union all
		select 'OIV', 'Ore invoiri'
		union all
		select 'ONE', 'Ore nemotivate'
		union all 
		select 'CFS', 'Ore concediu fara salar'
		union all 
		select 'OBL', 'Ore obligatii cetatenesti'
		union all 
		select 'IT1', 'Ore intrerupere tehnologica 1'
		union all
		select 'IT2', 'Ore intrerupere tehnologica 2'
		union all
		select 'OD', 'Ore delegatie'
		union all
		select 'ODT', 'Ore detasare'
		union all
		select 'ONO', 'Ore de noapte'
		
	return
end
