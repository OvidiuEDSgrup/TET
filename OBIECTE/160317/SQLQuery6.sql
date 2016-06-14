declare @p2 xml
set @p2=convert(xml,N'<row codMeniu="SD" tipdocument="" stare="0" denumire="" culoare="" modificabil="1" inCurs="0" tipMacheta="C" tip="" subtip="" update="0" searchText=" "/>')
exec wACTipuriDocument @sesiune='BAC16309C9390',@parXML=@p2

select * from webconfigform f where f.ProcSQL='wACTipuriDocument'
select * FROM WEBCONFIGFORM F where f.Meniu='pj'
select * from webconfigform f where f.DataField like '@meniu%'

select top 100 stare,* from pozdoc p 
order by p.idPozDoc desc

select * from doc d where d.Stare=1
order by d.Data desc