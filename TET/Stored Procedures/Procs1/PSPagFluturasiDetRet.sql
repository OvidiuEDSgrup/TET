--***
/**	procedura pt. paginare fluturasi cu detaliere retineri */
Create
procedure PSPagFluturasiDetRet
@DataJ datetime, @DataS datetime, @Ordonare char(30), @ModGrafic int
As
Begin
declare @ListeSaltPagLmNou int, @numar_pozitie float, @tip_form char(1), @marca_i char(6), @loc_de_munca_i char(9), @text_i char(20), 
@ore_procent_i char(8), @valoare_i float, 
@marca_p char(6), @loc_de_munca_i1 char(9), @text_p char(20), @ore_procent_p char(8), @valoare_p float, 
@marca char(6), @loc_de_munca_i2 char(9), @text char(20), @ore_procent char(8), @valoare float, @nr_linie int, 
@nr_linii_fluturas int
declare @gnumar_pozitie float, @gtip_form char(1), @numar_liniile float, @lm_ant char(9), @gfetch int
set @ListeSaltPagLmNou=dbo.iauParL('PS','SALT_LIST')

declare tmp_flutur cursor for
select a.numar_pozitie, a.tip_form , a.marca_i, n1.loc_de_munca, a.text_i, a.ore_procent_i, a.valoare_i, 
a.marca_p, n2.loc_de_munca, a.text_p , a.ore_procent_p, a.valoare_p, a.marca, n3.loc_de_munca, a.text, a.ore_procent, a.valoare, a.nr_linie, 
(case when (select count(1) from flutur b where  
b.numar_pozitie>=(select top 1 d.numar_pozitie from flutur d where d.numar_pozitie<=a.numar_pozitie and d.tip_form='H' order by d.numar_pozitie desc) 
and b.numar_pozitie<(select top 1 numar_pozitie from flutur c where c.numar_pozitie>a.numar_pozitie and c.tip_form='H' order by c.numar_pozitie))<>0 
then 
(select count(1) from flutur b where  
b.numar_pozitie>=(select top 1 d.numar_pozitie from flutur d where d.numar_pozitie<=a.numar_pozitie and d.tip_form='H' order by d.numar_pozitie desc) 
and b.numar_pozitie<(select top 1 numar_pozitie from flutur c where c.numar_pozitie>a.numar_pozitie and c.tip_form='H' order by c.numar_pozitie)) 
else 
(select count(1) from flutur b where  
b.numar_pozitie>=(select top 1 d.numar_pozitie from flutur d where d.numar_pozitie<=a.numar_pozitie and d.tip_form='H' order by d.numar_pozitie desc) 
and (select count(1) from flutur e where e.numar_pozitie>a.numar_pozitie and e.tip_form='H')=0) end)
from flutur a
left outer join net n1 on a.marca_i=n1.marca and n1.data=@DataS
left outer join net n2 on a.marca_p=n2.marca and n2.data=@DataS
left outer join net n3 on a.marca=n3.marca and n3.data=@DataS
order by a.numar_pozitie, a.tip_form, a.marca_i

open tmp_flutur
fetch next from tmp_flutur into @numar_pozitie, @tip_form, @marca_i, @loc_de_munca_i, @text_i , @ore_procent_i, @valoare_i, 
@marca_p, @loc_de_munca_i1, @text_p, @ore_procent_p, @valoare_p, 
@marca, @loc_de_munca_i2, @text, @ore_procent, @valoare, @nr_linie, @nr_linii_fluturas

Set @numar_liniile = 0
Set @gfetch = @@fetch_status
while @@fetch_status = 0
Begin
	Set @numar_liniile = @numar_liniile +(case when @tip_form='H' then 9 else 1 end)
	Set @numar_liniile = (case when @tip_form='H' and (@numar_liniile+@nr_linii_fluturas>(case when @ModGrafic=1 then 69 else 65 end) or
 	@ListeSaltPagLmNou=1 and @loc_de_munca_i<>@lm_ant and @Ordonare<>'Nume') then 9 else @numar_liniile end)
	update flutur set nr_linie = @numar_liniile where numar_pozitie=@numar_pozitie and tip_form=@tip_form
	Set @lm_ant = (case when @loc_de_munca_i2<>'' then @loc_de_munca_i2 when @loc_de_munca_i1<>''
  	then @loc_de_munca_i1 else @loc_de_munca_i end)

	fetch next from tmp_flutur into @numar_pozitie, @tip_form, @marca_i, @loc_de_munca_i, @text_i, @ore_procent_i, 
 	@valoare_i, @marca_p, @loc_de_munca_i1, @text_p, @ore_procent_p, @valoare_p, @marca, @loc_de_munca_i2, 
 	@text, @ore_procent, @valoare, @nr_linie, @nr_linii_fluturas
End
close tmp_flutur
Deallocate tmp_flutur
End
