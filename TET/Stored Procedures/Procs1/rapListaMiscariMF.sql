--***
create procedure rapListaMiscariMF (@dataj datetime, @datas datetime
			,@TipLista varchar(3)		-->	I=Intrari, E=Iesiri, M=Modificari, T=transferuri, CON=conservari, CIN=Inchirieri3
			,@tip_misc varchar(10)		-->	tip miscare, depinde de tipLista
			,@valuta varchar(40), @gestiune varchar(40), @lmunca varchar(40), @lm_strict int
			,@nrinv varchar(40)			--> un mijloc fix
			,@contmf varchar(50)=null	--> filtru cont; (se presupune ca e de imobilizare)
			)
as

set transaction isolation level read uncommitted

select
	(case when @TipLista='E' then isnull((select top 1 curs from curs where valuta=@valuta and data<=data_miscarii order by data desc),1)
		else 1 end) as curs,
	isnull((select top 1 data from curs where valuta=@valuta and data<=data_miscarii order by data desc),1) as data,
	t1.Subunitate, t1.Data_lunii_de_miscare, t1.Numar_de_inventar, t1.Tip_miscare Tip_miscare, 
	t1.Numar_document, t1.Data_miscarii, t1.Tert, t1.Factura, t1.Pret, t1.TVA, t1.Cont_corespondent, t1.Loc_de_munca_primitor, 
	t1.Gestiune_primitoare Gestiune_primitoare, t1.Diferenta_de_valoare, t1.Data_sfarsit_conservare, t1.Subunitate_primitoare,
	t1.Procent_inchiriere, t3.denumire,t3.cod_de_clasificare, t3.data_punerii_in_functiune,t2.cont_mijloc_fix, t2.loc_de_munca,
	t2.gestiune, t2.durata,	t2.valoare_de_inventar, t2.valoare_amortizata, t2.valoare_amortizata_cont_8045, 
	case when (@TipLista='CON') then case when (left(cod_de_clasificare,1)= '2') 
					then left(cod_de_clasificare,1)+substring(cod_de_clasificare,3,1) 
					else left(cod_de_clasificare,1) end
				else t2.categoria  end as categoria,
	lm.denumire den_lm, t2.numar_de_luni_pana_la_am_int, rtrim(t.Denumire) as denTert
from misMF t1 
	left outer join fisamf t2 on t1.numar_de_inventar=t2.numar_de_inventar and t1.subunitate=t2.subunitate 
		and t2.data_lunii_operatiei=t1.data_lunii_de_miscare
	left outer join mfix t3 on t1.numar_de_inventar=t3.numar_de_inventar and t1.subunitate=t3.subunitate
	left join lm on lm.cod=t2.loc_de_munca
	left join terti t on t1.tert=t.tert
where data_miscarii between @dataj and @datas
	and
	(   @TipLista='I' and t2.felul_operatiei='3'
		or @TipLista='E' and t2.felul_operatiei='5'
		or @TipLista='T' and t2.felul_operatiei = '6'
		or @TipLista='M' and t2.felul_operatiei='1'
		or @TipLista='CON' and t2.felul_operatiei='1'
		or @TipLista='CIN' and t2.felul_operatiei='7'
	)
	and (isnull(@gestiune,'nulllll')='nulllll' or rtrim(@gestiune)=rtrim(t2.gestiune)
		 or @TipLista='T' and rtrim(@gestiune)=rtrim(t1.gestiune_primitoare))
	and (isnull(@lmunca,'nulllll')='nulllll' 
		or @lm_strict=0 and t2.loc_de_munca like rtrim(@lmunca)+'%'	or rtrim(@lmunca)=rtrim(t2.loc_de_munca) 
		or @TipLista='T' and (@lm_strict=0 and t1.Loc_de_munca_primitor like rtrim(@lmunca)+'%' or rtrim(@lmunca)=rtrim(t1.Loc_de_munca_primitor)))
	and (isnull(@nrinv,'nulllll')='nulllll' or rtrim(@nrinv)=rtrim(t1.Numar_de_inventar))
	and (substring(@tip_misc,2,1)='T' and left(tip_miscare,1)=@TipLista or tip_miscare=@TipLista
		or tip_miscare = @tip_misc)
	and (isnull(@contmf,'nulllll')='nulllll' or rtrim(t2.cont_mijloc_fix) like rtrim(@contmf)+'%')
	and (t3.denumire!='')
order by data,t2.loc_de_munca,t1.numar_de_inventar
