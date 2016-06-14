select * from webConfigSTDMeniu s left join webConfigMeniu w on ISNULL(w.Meniu,'')=ISNULL(s.Meniu,'')
where w.Meniu is null

-- insert webConfigTipuri
select s.*,detalii=null from webConfigSTDTipuri s left join webConfigTipuri w on ISNULL(w.Meniu,'')=ISNULL(s.Meniu,'') AND ISNULL(w.Tip,'')=ISNULL(s.Tip,'')
	AND ISNULL(w.Subtip,'')=ISNULL(s.Subtip,'') 
	--AND ISNULL(w.Ordine,'')=ISNULL(s.Ordine,'')
where w.Meniu is null

-- insert webConfigGrid 
select s.*,detalii=null from webConfigSTDGrid s left join webConfigGrid w on ISNULL(w.Meniu,'')=ISNULL(s.Meniu,'') AND ISNULL(w.Tip,'')=ISNULL(s.Tip,'')
	AND ISNULL(w.Subtip,'')=ISNULL(s.Subtip,'') AND ISNULL(w.DataField,'')=ISNULL(s.DataField,'') AND ISNULL(w.InPozitii,'')=ISNULL(s.InPozitii,'')
	--AND ISNULL(w.Ordine,'')=ISNULL(s.Ordine,'')
where w.Meniu is null

-- insert webConfigTaburi
select s.*,detalii=null,1 from webConfigSTDTaburi s left join webConfigTaburi w on ISNULL(w.MeniuSursa,'')=ISNULL(s.MeniuSursa,'') 
	AND ISNULL(w.TipSursa,'')=ISNULL(s.TipSursa,'')
	AND ISNULL(w.NumeTab,'')=ISNULL(s.NumeTab,'') 
where w.MeniuSursa is null

-- insert WebConfigForm
select s.* from webConfigSTDForm s left join WebConfigForm w on ISNULL(w.Meniu,'')=ISNULL(s.Meniu,'') AND ISNULL(w.Tip,'')=ISNULL(s.Tip,'')
	AND ISNULL(w.Subtip,'')=ISNULL(s.Subtip,'') AND ISNULL(w.DataField,'')=ISNULL(s.DataField,'')
where w.Meniu is null

-- insert webConfigFiltre
select s.*,detalii=null from webConfigSTDFiltre s left join webConfigFiltre w on ISNULL(w.Meniu,'')=ISNULL(s.Meniu,'') AND ISNULL(w.Tip,'')=ISNULL(s.Tip,'')
	AND ISNULL(w.DataField1,'')=ISNULL(s.DataField1,'')
where w.Meniu is null