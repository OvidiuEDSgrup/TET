
CREATE procedure wIaProgramLucru @sesiune VARCHAR(50), @parXML XML
as
declare @f_program varchar(50), @f_lm varchar(9), @f_denlm varchar(50), @f_marca varchar(6), @f_densalariat varchar(50), 
	@f_tipprogramare varchar(50), @parXML1 XML, @parXML2 XML

set @f_program = @parXML.value('(/*/@f_program)[1]', 'varchar(50)')
set @f_lm = @parXML.value('(/*/@f_lm)[1]', 'varchar(9)')
set @f_denlm = @parXML.value('(/*/@f_denlm)[1]', 'varchar(50)')
set @f_marca = @parXML.value('(/*/@f_marca)[1]', 'varchar(6)')
set @f_densalariat = @parXML.value('(/*/@f_densalariat)[1]', 'varchar(50)')
set @f_tipprogramare = @parXML.value('(/*/@f_tipprogramare)[1]', 'varchar(50)')

set @parXML1=(select 'TP' tip for xml raw)
set @parXML2=(select 'OP' tip for xml raw)

select (case when pl.marca<>'' then 'S' when pl.loc_de_munca<>'' then 'L' else 'U' end) as tipprogram,
	(case when pl.marca<>'' then 'Salariat' when pl.loc_de_munca<>'' then 'Loc de munca' else 'Unitate' end) as dentipprogram,
	pl.idProgramDeLucru, 
	rtrim(pl.Loc_de_munca) lm, rtrim(lm.Denumire) as denlm, 
	rtrim(pl.Marca) marca, rtrim(p.Nume) as densalariat, 
	rtrim(pl.Tip_programare) as tipprogramare, 
	rtrim(pl.Tip_ore_pontaj) as tiporepontaj, 
	rtrim(op.Denumire) as dentiporepontaj, 
	CONVERT(char(10),pl.data_inceput,101) as datainceput, 
	rtrim(pl.ora_start) as orastart, left(pl.ora_start,2)+':'+SUBSTRING(pl.ora_start,3,2) as orastartafis, 
	CONVERT(char(10),pl.data_sfarsit,101) as datasfarsit, 
	rtrim(pl.ora_stop) as orastop, left(pl.ora_stop,2)+':'+SUBSTRING(pl.ora_stop,3,2) as orastopafis, 
	pl.Ore_munca as oremunca, pl.Ore_odihna as oreodihna, pl.detalii
from ProgramLucru pl
	left outer join lm on lm.Cod=pl.Loc_de_munca
	left outer join personal p on p.Marca=pl.Marca
	left outer join wfTipProgramareOrePontaj (@sesiune, @parXML1) tp on pl.Tip_programare=tp.tip
	left outer join wfTipProgramareOrePontaj (@sesiune, @parXML2) op on pl.Tip_ore_pontaj=op.tip
where (@f_program is null or (case when pl.marca<>'' then 'Salariat' when pl.loc_de_munca<>'' then 'Loc de munca' else 'Unitate' end) like '%'+@f_program+'%')
	and (@f_lm is null or pl.Loc_de_munca like @f_lm+'%')
	and (@f_denlm is null or lm.Denumire like '%'+@f_denlm+'%')
	and (@f_marca is null or pl.Marca like @f_marca+'%')
	and (@f_densalariat is null or p.Nume like '%'+@f_densalariat+'%')
	and (@f_tipprogramare is null or tp.denumire like '%'+@f_tipprogramare+'%')
order by datainceput desc, orastart, (case when pl.marca<>'' then '1' when pl.loc_de_munca<>'' then '2' else '3' end)
for xml raw, root('Date')

select '1' AS areDetaliiXml
for xml raw, root('Mesaje')
