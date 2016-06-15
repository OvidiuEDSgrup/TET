--***
create function dbo.f_wmIaForm(@meniu varchar(20))
returns xml
as
begin
	return 
	(select wf.Nume nume, TipObiect tipobiect, DataField datafield, 
		(case when len(LabelField)>1 then LabelField else null end) labelfield, 
		(case when len(ProcSQL)>1 then ProcSQL else null end) procsql, 
		(case when len(ListaValori)>1 then ListaValori else null end) listavalori, 
		(case when len(ListaEtichete)>1 then ListaEtichete else null end) listaetichete, 
		(case when len(Prompt)>0 then Prompt else null end) as prompt,
		(case when len(Initializare)>0 then Initializare else null end) initializare, 
		Modificabil modificabil
	from webConfigFormMobile wf where  wf.identificator=@meniu and wf.Vizibil=1
	order by wf.Ordine
	for XML raw,type)
end
