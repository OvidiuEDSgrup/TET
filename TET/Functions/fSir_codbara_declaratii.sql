--***
/**	functie sir codbara declaratii	*/
Create function  fSir_codbara_declaratii ()
returns char(2000)
as
begin
declare @Sir_codbara char(2000), @Data datetime, @cod_declaratie char(20), @cod_declaratie_initiala char(20), @cod_fiscal char(13), @Luna char(2), @Anul char(4), @Cod_contributie char(20), @Nr_evidenta_platii char(40), @Suma_datorata_initiala float, @Suma_datorata_corectata float, @Suma_deductibila_initiala float, @Suma_deductibila_corectata float, @Suma_de_plata_initiala float, @Suma_de_plata_corectata float, @Suma_de_recuperat_initiala float, @Suma_de_recuperat_corectata float, @Ord1 char(20), 
@Ord2 char(20), @cTerm char(8)
Set @cTerm = (select convert(char(8), abs(convert(int, host_id()))))
Set @cod_fiscal=dbo.iauParA('GE','CODFISC')
declare contributii_sociale cursor for 
select a.Data, a.Cod_declaratie, '' as Cod_declaratie_initiala, a.Cod_contributie, a.Nr_evidenta_plati, a.Suma_datorata, 0, a.Deductibila, 0, a.Suma_de_plata, 0,  a.Suma_de_recuperat, 0, 
'' as Ord1, a.cod_contributie as Ord2
from contrsoc a, avnefac b
where b.Numar<>'710' and a.Data=b.Data and a.Cod_declaratie=b.Numar and b.Terminal=@cTerm and b.Tip='DS'
union all 
select a.Data, a.Cod_declaratie, c.Cod_declaratie as Cod_declaratie_initiala, a.Cod_contributie, a.Nr_evidenta_plati, c.Suma_datorata, a.Suma_datorata, c.Deductibila, a.Deductibila,  c.Suma_de_plata, a.Suma_de_plata,  c.Suma_de_recuperat, a.Suma_de_recuperat, 
c.Cod_declaratie as Ord1, a.cod_contributie as Ord2
from contrsoc a, avnefac b, contrsoc c
where b.Numar='710' and a.Data=b.Data and a.Cod_declaratie=b.Numar and b.Terminal=@cTerm and b.Tip='DS' and 
a.Data=c.Data and a.Cod_contributie=c.Cod_contributie and c.Cod_declaratie<>'710'
order by Ord1, Ord2
open contributii_sociale
fetch next from contributii_sociale into @Data, @Cod_declaratie, @cod_declaratie_initiala, @Cod_contributie, @Nr_evidenta_platii, @Suma_datorata_initiala, @Suma_datorata_corectata, @Suma_Deductibila_initiala, @Suma_Deductibila_corectata, @Suma_de_plata_initiala, @Suma_de_plata_corectata, @Suma_de_recuperat_initiala, @Suma_de_recuperat_corectata, @Ord1, @Ord2
Set @Luna=(case when month(@Data)<10 then '0' else '' end)+rtrim(ltrim(convert(char(2),month(@Data))))
Set @Anul=convert(char(4),year(@Data))
Set @Sir_codbara = rtrim(@Cod_declaratie)+','+rtrim(@Cod_fiscal)+','+@Luna+','+@Anul+'*'
While @@fetch_status = 0 
Begin
	if @Cod_declaratie='710'
	Begin
		Set @Sir_codbara = rtrim(@Sir_codbara)+rtrim(@cod_declaratie_initiala)+','+rtrim(@Cod_contributie)+','+ 				rtrim(@Nr_evidenta_platii)+','+rtrim(convert(char(10),@Suma_datorata_initiala))+','+ 						rtrim(convert(char(10),@Suma_datorata_corectata))+','+rtrim(convert(char(10),@Suma_deductibila_initiala))+','+ 				rtrim(convert(char(10),@Suma_deductibila_corectata))+','+rtrim(convert(char(10),@Suma_de_plata_initiala))+','+ 				rtrim(convert(char(10),@Suma_de_plata_corectata))+','+rtrim(convert(char(10),@Suma_de_recuperat_initiala))+','+ 			rtrim(convert(char(10),@Suma_de_recuperat_corectata))+'*'
	End
	else
	Begin
		Set @Sir_codbara = rtrim(@Sir_codbara)+rtrim(@Cod_contributie)+','+rtrim(@Nr_evidenta_platii)+','+
		rtrim(convert(char(10),@Suma_datorata_initiala))+','+rtrim(convert(char(10),@Suma_deductibila_initiala))+','+
		rtrim(convert(char(10),@Suma_de_plata_initiala))+','+rtrim(convert(char(10),@Suma_de_recuperat_initiala))+'*'
	End
	fetch next from contributii_sociale into @Data, @Cod_declaratie, @cod_declaratie_initiala, @Cod_contributie, @Nr_evidenta_platii, @Suma_datorata_initiala, @Suma_datorata_corectata, @Suma_Deductibila_initiala, @Suma_Deductibila_corectata, 	@Suma_de_plata_initiala, @Suma_de_plata_corectata, @Suma_de_recuperat_initiala, @Suma_de_recuperat_corectata, @Ord1, @Ord2
End
close contributii_sociale
Deallocate contributii_sociale
return @Sir_codbara
end
