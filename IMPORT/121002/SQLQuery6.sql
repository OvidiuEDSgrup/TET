
select [Cod_indicator] ,
		[Tip] ,
		[Data] ,
		[Element_1] ,
		[Element_2] ,
		[Element_3] ,
		[Element_4] ,
		[Element_5] 
from expval
group by
[Cod_indicator] ,
		[Tip] ,
		[Data] ,
		[Element_1] ,
		[Element_2] ,
		[Element_3] ,
		[Element_4] ,
		[Element_5]
		having COUNT(*)>1
		
		