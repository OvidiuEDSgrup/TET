--***
/**	procedura calcul impozit	*/
Create 
procedure calcul_impozit_salarii
	@Venit_baza_impozit float, @Impozit_calculat float output, @Calcul_impozit_anual int
As
Begin
	Select @Impozit_calculat = a.Suma_fixa+round((@Venit_baza_impozit- 
		(case when a.Numar_curent=1 then 0 
		else isnull((select top 1 limita from impozit b where b.Tip_impozit=a.Tip_impozit and b.Numar_curent>=(case when a.Numar_curent>1 then a.Numar_curent-1 else 1 end) order by b.Tip_impozit, b.Numar_curent),0) end))*a.Procent/100,0)
	from impozit a 
	where a.Tip_impozit=(case when @Calcul_impozit_anual=1 then 'A' else 'P' end) and a.Limita>=@Venit_baza_impozit 
		and a.Numar_curent in (select top 1 c.numar_curent from impozit c where c.tip_impozit=a.Tip_impozit and c.Limita>=@Venit_baza_impozit order by c.Numar_curent)
	order by a.Numar_curent
End
