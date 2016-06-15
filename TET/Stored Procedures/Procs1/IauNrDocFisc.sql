--***
CREATE PROCEDURE IauNrDocFisc @Jurnal char(3), @TipDoc char(1), @Serie char(9), @NumarInf int
AS

declare @Numar int
set @Numar = 0

update docfisc
set ultimul_nr = ultimul_nr + (case when ultimul_nr >= nr_sup then 0 else 1 end), 
	@Numar = (case when ultimul_nr >= nr_sup then @Numar else ultimul_nr + 1 end)
where Jurnal=RTrim(@Jurnal) and Tip_doc=@TipDoc and serie=RTrim(@Serie) and nr_inf=@NumarInf

select @Numar as Numar
