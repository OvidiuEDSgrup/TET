--***
/**	functie modulo	*/
Create function modulo (@nr1 float, @nr2 float) 
Returns int
As
Begin
	Declare @rest float
	Set @rest = @nr1-floor(@nr1/@nr2)*@nr2
	return(@rest)
end
