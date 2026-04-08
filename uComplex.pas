unit uComplex;

interface

uses SysUtils, Types;

type
  TComplex = record
    Re: Double;
    Im: Double;
  end;

function CompN(const Rech, Imch: Double): TComplex; inline;
function Slozh(const Arg1, Arg2: TComplex): TComplex; inline;
function Vychit(const Arg1, Arg2: TComplex): TComplex; inline;
function Umnozh(const Arg1, Arg2: TComplex): TComplex; inline;
function Delen(const Arg1, Arg2: TComplex): TComplex; inline;
function ModCN(const Arg: TComplex): Double; inline;
function ArgCN(const Arg: TComplex): Double; inline;
function ExpI(const Arg: Double): TComplex; inline;

implementation

function CompN(const Rech, Imch: Double): TComplex;
begin
  Result.Re := Rech;
  Result.Im := Imch;
end;

function Slozh(const Arg1, Arg2: TComplex): TComplex;
begin
  Result.Re := Arg1.Re + Arg2.Re;
  Result.Im := Arg1.Im + Arg2.Im;
end;

function Vychit(const Arg1, Arg2: TComplex): TComplex;
begin
  Result.Re := Arg1.Re - Arg2.Re;
  Result.Im := Arg1.Im - Arg2.Im;
end;

function Umnozh(const Arg1, Arg2: TComplex): TComplex;
begin
  Result.Re := (Arg1.Re * Arg2.Re) - (Arg1.Im * Arg2.Im);
  Result.Im := (Arg1.Im * Arg2.Re) + (Arg1.Re * Arg2.Im);
end;

function Delen(const Arg1, Arg2: TComplex): TComplex;
begin
  if (Arg2.Re <> 0) and (Arg2.Im <> 0) then
    begin
      Result.Re := ((Arg1.Re * Arg2.Re) + (Arg1.Im * Arg2.Im)) / (sqr(Arg2.Re) + sqr(Arg2.Im));
      Result.Im := ((Arg1.Im * Arg2.Re) - (Arg1.Re * Arg2.Im)) / (sqr(Arg2.Re) + sqr(Arg2.Im));
    end
  else
    begin
      Result.Re := 0 / 0;
      Result.Im := 0 / 0;
    end;
end;

function ModCN(const Arg: TComplex): Double;
begin
  Result:=sqrt(sqr(Arg.Re) + sqr(Arg.Im));
end;

function ArgCN(const Arg: TComplex): Double;
begin
  Result := ArcTan(Arg.Im / Arg.Re);
end;

function ExpI(const Arg: Double): TComplex;
begin
  Result.Re := cos(Arg);
  Result.Im := sin(Arg);
end;

end.
 