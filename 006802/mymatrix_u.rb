#!/usr/bin/ruby -s
# -*- Ruby -*-

# 「프로그래머를 위한 선형대수」샘플코드
# (平岡和幸, 堀玄, 옴사, 2004. ISBN 4-274-06578-2)
# http://ssl.ohmsha.co.jp/cgi-bin/menu.cgi?ISBN=4-274-06578-2

# $Id: mymatrix.rb,v 1.13 2004/10/06 09:18:00 hira Exp $

# Copyright (c) 2004, HIRAOKA Kazuyuki <hira@ics.saitama-u.ac.jp>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#    * Redistributions of source code must retain the above copyright
#      notice,this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#    * Neither the name of the HIRAOKA Kazuyuki nor the names of its
#      contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#########################################################

# "가감승제"나 "LU 분해에 의한 역행렬 · 일차 방정식"학습용 코드입니다.
# 어디까지나 계산 단계를 나타내는 것이 목적입니다.
# 실제에는 matrix.rb (ruby 표준 탑재) 등을 사용하는 것이 좋습니다.

# Ruby 쓰시는 여러분께:
#
# 죄송합니다. Ruby답게 쓰는 법을 극도로 피하고 있습니다.
# 목표는 "많은 사람이 읽을 수있게"여서 그렇습니다.

# Ruby 안쓰시는 여러분께:
#
# "동작하는 의사 코드 "로 읽어주세요.
# 어떠한 주요 언어라도 사용한 경험이 있으면 감으로 이해할 수 있을 것입니다.
# (진짜 Ruby가 이런 어색한 것이라고 오해하지 않도록만 부탁드립니다).
# 보시는 바와 같이 "#"에서 그 줄의 끝까지는 주석입니다.
#
# ▼은 "특히 언어 의존적인 부분"입니다. 내용은 신경 쓰지 않아도 괜찮습니다.
# 예제에 주목하여 사용법만 확인하세요.

#########################################################
# ▼용법

def matrix_usage()
  name = File::basename $0
  print <<EOU
#{name}: 행렬 계산 샘플 코드
(각종 테스트)
  #{name} -t=make   → 생성
  #{name} -t=print  → 표시
  #{name} -t=arith  → 곱, 정수배
  #{name} -t=op     → + - *
  #{name} -t=lu    → LU 분해
  #{name} -t=det    → 행렬식
  #{name} -t=sol    → 연립일차방정식
  #{name} -t=inv    → 역행렬
  #{name} -t=plu    → LU 분해 (pivoting 추가)
EOU
end

def matrix_test(section)
  standalone = (__FILE__ == $0)  # 직접 실행(다른 파일로부터 로딩되는 것이 아닌)
  matched = (section == $t)  # -t= 옵션 값과 section이 일치하는지
  return (standalone and matched)
end

if (matrix_test(nil)) # 직접기동이면서 -t없는 경우
  matrix_usage()
end

#########################################################
# ▼벡터・행렬의 생성과 접근

# 인수의 범위 확인은 넘어갔습니다

### 벡터

class MyVector
  def initialize(n)
    @a = Array::new(n)
    for i in 0...n
      @a[i] = nil
    end
  end
  def [](i)
    return @a[i-1]
  end
  def []=(i, x)
    @a[i-1] = x
  end
  def dim
    return @a.length
  end
end

def make_vector(dim)
  return MyVector::new(dim)
end
def vector(elements)
  dim = elements.length
  vec = make_vector(dim)
  for i in 1..dim
    vec[i] = elements[i-1]
  end
  return vec
end
def vector_size(vec)
  return vec.dim
end
def vector_copy(vec)
  dim = vector_size(vec)
  new_vec = make_vector(dim)
  for i in 1..dim
    new_vec[i] = vec[i]
  end
  return new_vec
end

### 행렬

class MyMatrix
  def initialize(m, n)
    @a = Array::new(m)
    for i in 0...m
      @a[i] = Array::new(n)
      for j in 0...n
        @a[i][j] = nil
      end
    end
  end
  def [](i, j)
    return @a[i-1][j-1]
  end
  def []=(i, j, x)
    @a[i-1][j-1] = x
  end
  def dim
    return @a.length, @a[0].length
  end
end

def make_matrix(rows, cols)
  return MyMatrix::new(rows, cols)
end
def matrix(elements)
  rows = elements.length
  cols = elements[0].length
  mat = make_matrix(rows, cols)
  for i in 1..rows
    for j in 1..cols
      mat[i,j] = elements[i-1][j-1]
    end
  end
  return mat
end
def matrix_size(mat)
  return mat.dim
end
def matrix_copy(mat)
  rows, cols = matrix_size(mat)
  new_mat = make_matrix(rows, cols)
  for i in 1..rows
    for j in 1..cols
      new_mat[i,j] = mat[i,j]
    end
  end
  return new_mat
end

### 예

if (matrix_test('make'))
  puts('- vector -')  # → "- vector -"라고 표시하고 줄바꿈

  puts('Make vector v = [2,9,4]^T, show v[2] and size of v.')
  v = make_vector(3)  # 3 차원 종벡터를 생성
  v[1] = 2
  v[2] = 9
  v[3] = 4
  puts(v[2])  # → 9 를 표시하고 줄바꿈
  puts(vector_size(v))  # → 3 (차원)

  puts('Make vector w = [2,9,4]^T and show w[2].')
  w = vector([2,9,4])  # 같은 벡터를 생성하는 다른 방법
  puts(w[2])  # → 9

  puts('Copy v to x and show x[2].')
  x = vector_copy(v)  # 복제
  puts(x[2])  # → 9
  puts('Modify x[2] and show x[2] again.')
  x[2] = 0
  puts(x[2])  # → 0
  puts('Original v[2] is not modified.')
  puts(v[2])  # → 9

  puts('- matrix -')

  puts('Make matrix A = [[2 9 4] [7 5 3]] and show a[2,1].')
  a = make_matrix(2, 3)  # 2×3 행렬을 생성
  a[1,1] = 2
  a[1,2] = 9
  a[1,3] = 4
  a[2,1] = 7
  a[2,2] = 5
  a[2,3] = 3
  puts(a[2,1])  # → 7
  puts('Show size of A.')
  rows, cols = matrix_size(a)  # a의 크기를 획득
  puts(rows)  # → 2
  puts(cols)  # → 3

  puts('Make matrix B = [[2 9 4] [7 5 3]] and show b[2,1].')
  b = matrix([[2,9,4], [7,5,3]])  # 같은 행렬을 생성하는 다른 방법
  puts(b[2,1])  # → 7

  puts('Copy A to C and show c[2,1].')
  c = matrix_copy(a)  # 복제
  puts(c[2,1])  # → 7
  puts('Modify c[2,1] and show c[2,1] again.')
  c[2,1] = 0
  puts(c[2,1])  # → 0
  puts('Original a[2,1] is not modified.')
  puts(a[2,1])  # → 7
end

#########################################################
# 벡터・행렬의 표시

# 벡터를 표시하는 함수 vector_print 를 정의. 사용법은 예를 참조.
def vector_print(vec)
  dim = vector_size(vec)
  for i in 1..dim  # i = 1, 2, ..., dim 에 대해 순환 (end까지)
    printf('%5.4g ', vec[i])  # 5 글자분의 폭을 확보하여 4째자리까지 표시
    puts('')  # 줄바꿈
  end
  puts('')
end

def matrix_print(mat)
  rows, cols = matrix_size(mat)
  for i in 1..rows
    for j in 1..cols
      printf('%5.4g ', mat[i,j])
    end
    puts('')
  end
  puts('')
end

# 일일이 "vector_print" "matrix_print"하기에는 길기 때문에...
def vp(mat)
  vector_print(mat)
end
def mp(mat)
  matrix_print(mat)
end

### 예

if (matrix_test('print'))
  puts('Print vector [3,1,4]^T twice.')
  v = vector([3,1,4])
  vector_print(v)
  vp(v)
  puts('Print matrix [[2 9 4] [7 5 3]] twice.')
  a = matrix([[2,9,4], [7,5,3]])
  matrix_print(a)
  mp(a)
end

#########################################################
# 벡터・행렬의 곱, 정수배

### 벡터

# 합(벡터 a에 벡터 b를 더한다: a ← a+b) --- 「#」이후는 코멘트
def vector_add(a, b)       # 함수 정의(end까지)
  a_dim = vector_size(a)   # 각 벡터의 차원을 취득
  b_dim = vector_size(b)
  if (a_dim != b_dim)      # 차원이 같지 않으면...(end까지)
    raise 'Size mismatch.' # 에러
  end
  # ここからが本題
  for i in 1..a_dim        # 루프(end까지): i = 1, 2, ..., a_dim
    a[i] = a[i] + b[i]     # 성분마다 더한다.
  end
end

# 정수배 (벡터 vec를 num배)
def vector_times(vec, num)
  dim = vector_size(vec)
  for i in 1..dim
    vec[i] = num * vec[i]
  end
end

### 행렬

# 합(벡터 a에 벡터 b를 더한다: a ← a+b)
def matrix_add(a, b)
  a_rows, a_cols = matrix_size(a)
  b_rows, b_cols = matrix_size(b)
  if (a_rows != b_rows)
    raise 'Size mismatch (rows).'
  end
  if (a_cols != b_cols)
    raise 'Size mismatch (cols).'
  end
  for i in 1..a_rows
    for j in 1..a_cols
      a[i,j] = a[i,j] + b[i,j]
    end
  end
end

# 정수배 (행렬 mat을 num배)
def matrix_times(mat, num)
  rows, cols = matrix_size(mat)
  for i in 1..rows
    for j in 1..cols
      mat[i,j] = num * mat[i,j]
    end
  end
end

# 행렬 a와 벡터 v의 곱을 벡터 r에 격납(넣어둠)
def matrix_vector_prod(a, v, r)
  # 사이즈(크기)를 취득
  a_rows, a_cols = matrix_size(a)
  v_dim = vector_size(v)
  r_dim = vector_size(r)
  # 곱이 정의되는지 확인
  if (a_cols != v_dim or a_rows != r_dim)
    raise 'Size mismatch.'
  end
  # 여기부터가 본제(중심내용). a의 각 행에 대해...
  for i in 1..a_rows
    # a와 v의 대응하는 성분을 곱하여 그 합계를 구한다.
    s = 0
    for k in 1..a_cols
      s = s + a[i,k] * v[k]
    end
    # 결과를 r에 저장
    r[i] = s
  end
end

# 행렬 a와 행렬 b의 곱을 행렬 r에 저장
def matrix_prod(a, b, r)
  # 사이즈(크기)를 취득하고, 곱이 정의되었는지 확인
  a_rows, a_cols = matrix_size(a)
  b_rows, b_cols = matrix_size(b)
  r_rows, r_cols = matrix_size(r)
  if (a_cols != b_rows or a_rows != r_rows or b_cols != r_cols)
    raise 'Size mismatch.'
  end
  # 여기까지가 본제(중심내용). a의 각행. b의 각열에 대해...
  for i in 1..a_rows
    for j in 1..b_cols
      # a와 b의 대응하는 성분을 곱하여 그 합계를 구한다.
      s = 0
      for k in 1..a_cols
        s = s + a[i,k] * b[k,j]
      end
      # 결과를 r에 저장
      r[i,j] = s
    end
  end
end

### 예

if (matrix_test('arith'))
  puts('- vector -')

  v = vector([1,2])
  w = vector([3,4])

  c = vector_copy(v)
  vector_add(c,w)
  puts('v, w, v+w, and 10 v')
  vp(v)
  vp(w)
  vp(c)

  c = vector_copy(v)
  vector_times(c,10)
  vp(c)

  puts('- matrix -')

  a = matrix([[3,1], [4,1]])
  b = matrix([[10,20], [30,40]])

  c = matrix_copy(a)
  matrix_add(c, b)
  puts('A, B, A+B, and 10 A')
  mp(a)
  mp(b)
  mp(c)

  c = matrix_copy(a)
  matrix_times(c, 10)
  mp(c)

  r = make_vector(2)
  matrix_vector_prod(a, v, r)
  puts('A, v, and A v')
  mp(a)
  vp(v)
  vp(r)

  r = make_matrix(2,2)
  matrix_prod(a, b, r)
  puts('A, B, and A B')
  mp(a)
  mp(b)
  mp(r)
end

#########################################################
# ▼a + b 등과 같이 표기할 수 있게

class MyVector
  def +(vec)
    c = vector_copy(self)
    vector_add(c, vec)
    return c
  end
  def -@()  # 単項演算子「-」
    c = vector_copy(self)
    vector_times(c, -1)
    return c
  end
  def -(vec)
    return self + (- vec)
  end
  def *(x)
    dims = vector_size(self)
    if (dims == 1)
      return x * self[1]
    elsif x.is_a? Numeric
      c = vector_copy(self)
      vector_times(c, x)
      return c
    else
      raise 'Type mismatch.'
    end
  end
  def coerce(other)
    if other.is_a? Numeric
      return vector([other]), self
    else
      raise 'Unsupported type.'
    end
  end
end

class MyMatrix
  def +(mat)
    c = matrix_copy(self)
    matrix_add(c, mat)
    return c
  end
  def -@()  # 単項演算子「-」
    c = matrix_copy(self)
    matrix_times(c, -1)
    return c
  end
  def -(mat)
    return self + (- mat)
  end
  def *(x)
    rows, cols = matrix_size(self)
    if (rows == 1 and cols == 1)
      return x * self[1,1]
    elsif x.is_a? Numeric
      c = matrix_copy(self)
      matrix_times(c, x)
      return c
    elsif x.is_a? MyVector
      r = make_vector(cols)
      matrix_vector_prod(self, x, r)
      return r
    elsif x.is_a? MyMatrix
      x_rows, x_cols = matrix_size(x)
      r = make_matrix(rows, x_cols)
      matrix_prod(self, x, r)
      return r
    else
      raise 'Type mismatch.'
    end
  end
  def coerce(other)
    if other.is_a? Numeric
      return matrix([[other]]), self
    else
      raise 'Unsupported type.'
    end
  end
end

### 예

if (matrix_test('op'))
  puts('- vector -')
  x = vector([1,2])
  y = vector([3,4])
  puts('x, y')
  vp(x)
  vp(y)
  puts('x+y, -x, y-x, x*10, 10*x')
  vp(x + y)
  vp(- x)
  vp(y - x)
  vp(x * 10)
  vp(10 * x)

  puts('- matrix -')
  a = matrix([[3,1], [4,1]])
  b = matrix([[10,20], [30,40]])
  puts('A, B')
  mp(a)
  mp(b)
  puts('A+B, -A, B-A, A*10, 10*A, A*B')
  mp(a + b)
  mp(- a)
  mp(b - a)
  mp(a * 10)
  mp(10 * a)
  mp(a * b)
  puts('A, x, and A*x')
  mp(a)
  vp(x)
  vp(a * x)
end

#########################################################
# LU 분해(pivoting 없음)

# LU 분해(pivoting 없음)
# 행렬에 따라 0 나누기 오류가 발생한다.
# 결과는 mat 자신에 기록(좌하 부분이 L, 우상 부분이 U)
def lu_decomp(mat)
  rows, cols = matrix_size(mat)
  # 행수(rows)와 열수(cols) 중 짧은 쪽을 s로 둔다.
  if (rows < cols)
    s = rows
  else
    s = cols
  end
  # 여기부터가 본제(중심 내용)
  for k in 1..s
    # 이 단계에서, mat는 다음과 같이 (u, l은 U, L의 완성부분. r은 잔차.)
    #     u u u u u u
    #     l u u u u u
    #     l l r r r r  ←k행
    #     l l r r r r
    #     l l r r r r
    # 【아】 U의 제 k 행은, 이 단계에서 잔차 자체 → 아무것도 하지 않아도 된다
    # 【이】 L의 제 k 열을 계산
    # 일반적으로 나눗셈은 시간이 걸리므로, 나눗셈의 횟수를 줄이기 위해 다듬기
    x = 1.0 / mat[k,k]  # (mat[k,k]이 0이면, 여기서 0 나누기 에러)
    for i in (k+1)..rows
      mat[i,k] = mat[i,k] * x  # 요컨데 mat[i,k] / mat[k,k]
    end
    # 【우】 잔차를 갱신
    for i in (k+1)..rows
      for j in (k+1)..cols
        mat[i,j] = mat[i,j] - mat[i,k] * mat[k,j]
      end
    end
  end
end

# LU 분해의 결과를, 2개의 행렬 L, U 에 분할
def lu_split(lu)
  rows, cols = matrix_size(lu)
  # 행과 열 개수중 짧은 쪽을 r을 넣음
  if (rows < cols)
    r = rows
  else
    r = cols
  end
  # L은 rows×r, R은 r×cols
  lmat = make_matrix(rows, r)
  umat = make_matrix(r, cols)
  # L을 구한다
  for i in 1..rows
    for j in 1..r
      if (i > j)
        x = lu[i,j]
      elsif (i == j)  # else if
        x = 1
      else
        x = 0
      end
      lmat[i,j] = x
    end
  end
  # R을 구한다
  for i in 1..r
    for j in 1..cols
      if (i > j)
        x = 0
      else
        x = lu[i,j]
      end
      umat[i,j] = x
    end
  end
  return [lmat, umat]  # lmat과 umat의 쌍을 반환
end

### 예

if (matrix_test('lu'))
  a = matrix([[2,6,4], [5,7,9]])
  c = matrix_copy(a)
  lu_decomp(c)
  l, u = lu_split(c)
  puts('A, L, U, and L U')
  mp(a)
  mp(l)
  mp(u)
  mp(l * u)  # a와 동일
end

#########################################################
# 행렬식

# 행렬식(원래의 행렬은 파괴된다).
def det(mat)
  # 정방행렬인 것을 확인
  rows, cols = matrix_size(mat)
  if (rows != cols)
    raise 'Not square.'
  end
  # 여기부터가 본제(중심 내용). LU 분해하여...
  lu_decomp(mat)
  # U의 대각 성분의 곱을 답한다.
  x = 1
  for i in 1..rows
    x = x * mat[i,i]
  end
  return x
end

### 예

if (matrix_test('det'))
  a = matrix([[2,1,3,2], [6,6,10,7], [2,7,6,6], [4,5,10,9]])
  puts('A and det A = -12')
  mp(a)
  puts det(a)  # → -12
end

#########################################################
# 연립일차방정식

# 방정식 A x = y 를 푼다(A : 정방행렬, y : 벡터)
# A 는 파괴되어 해는 y에 기록됨(덮어 씀)
def sol(a, y)
  # 사이즈(크기) 확인은 생략
  # 우선 LU 분해
  lu_decomp(a)
  # 나머지는 하청에 맡긴다.
  sol_lu(a, y)
end

# (하청)방정식 L U x = y를 푼다. 해는 y에 기록(덮어 씀)
# L, U은 정방핼렬 A의 LU 분해 (정리해 하나의 행렬에 보관)
def sol_lu(lu, y)
  # 사이즈(크기)를 취득
  n = vector_size(y)
  # Lz = y로 푼다. 해 z는 y에 기록
  sol_l(lu, y, n)
  # Ux = y(내용은  z)를 푼다. 해 x는 y에 기록
  sol_u(lu, y, n)
end

# (재하청) Lx = y를 푼다. 해 z는 y에 기록(덮어씀) n은 y의 사이즈(크기)
# L, U은 정방핼렬 A의 LU 분해 (정리해 하나의 행렬에 보관)
def sol_l(lu, y, n)
  for i in 1..n
    # z[i] = y[i] - L[i,1] z[1] - ... - L[i,i-1] z[i-1]를 계산
    # 이미 구한 해 z[1], ..., z[i-1]은 y[1], ..., y[i-1]에 저장되어 있음
    for j in 1..(i-1)
      y[i] = y[i] - lu[i,j] * y[j]  # 질적으로는 y[i] - L[i,j] * z[j]
    end
  end
end

# (재하청) Ux = y를 푼다. 해 x는 y에 기록(덮어씀) n은 y의 사이즈(크기)
# L, U은 정방핼렬 A의 LU 분해 (정리해 하나의 행렬에 보관)
def sol_u(lu, y, n)
  #   i = n, n-1, ..., 1의 순서로 처리
  #   ※ 만약을 위해 주의:
  #   진짜 Ruby가 이런 어색한 언어라고 오해하지 마세요.
  #   Ruby를 몰라도 읽을 수 있도록 편리한 기능·기법은 자제하고 있습니다.
  for k in 0..(n-1)
    i = n - k
    # x[i] = (y[i] - U[i,i+1] x[i+1] - ... - U[i,n] x[n]) / U[i,i] 를 계산
    # 이미 구한 해 x[i+1], ..., x[n]은 y[i+1], ..., y[n]에 저장되어 있음
    for j in (i+1)..n
      y[i] = y[i] - lu[i,j] * y[j]  # 실질적으로는 y[i] - U[i,j] * x[j]
    end
    y[i] = y[i] / lu[i,i]
  end
end

### 예

if (matrix_test('sol'))
  a = matrix([[2,3,3], [3,4,2], [-2,-2,3]])
  c = matrix_copy(a)
  y = vector([9,9,2])
  puts('A, y, and solution x of A x = y.')
  mp(a)
  vp(y)
  sol(c, y)
  vp(y)
  puts('A x')
  vp(a*y)
end

#########################################################
# 행렬식

# 행렬식(원래의 행렬은 파괴된다).
def inv(mat)
  rows, cols = matrix_size(mat)
  # 정방행렬인 것을 확인
  rows, cols = matrix_size(mat)
  if (rows != cols)
    raise 'Not square.'
  end
  # 결과 저장 장소를 준비. 초기화해서 단위 행렬로 해둔다.
  ans = make_matrix(rows, cols)
  for i in 1..rows
    for j in 1..cols
      if (i == j)
        ans[i,j] = 1
      else
        ans[i,j] = 0
      end
    end
  end
  # 여기부터가 본제(중심 내용). LU 분해하여...
  lu_decomp(mat)
  for j in 1..rows
    # ans의 각 열을 오른쪽으로 해서, 연립 일차 방정식 A x = y를 해결.
    #   ※ 사실, ans의 각 열을 직접 잘라 sol_lu에 전달할하면 좋지만,
    #   그 방법은 언어 의존적. 어쩔 수 없어서 여기에서는 일부러
    #   (1)복사, (2)계산, (3)결과를 재작성, 과 같이 하고 있다.
    v = make_vector(cols)
    for i in 1..cols
      v[i] = ans[i,j]
    end
    sol_lu(mat, v)
    for i in 1..cols
      ans[i,j] = v[i]
    end
  end
  return(ans)
end

if (matrix_test('inv'))
  a = matrix([[2,3,3], [3,4,2], [-2,-2,3]])
  c = matrix_copy(a)
  b = inv(c)
  puts('A and B = inverse of A.')
  mp(a)
  mp(b)
  puts('A B and B A')
  mp(a*b)
  mp(b*a)
end

#########################################################
# LU 분해(pivoting 추가)
# 결과는 mat 그 자체에 덮어 쓰고 반환값으로 pivot table(벡터 p)를 돌려준다.
#
# 결과는,
# A' = L U (A'는 A의 행을 바꾼 것, L는 상삼각, U는 하삼각)인 분해.
# A'의  i번째 행은 원래 행렬 A의 p[i]번째 행.
# p_ref(mat, i, j, p)으로, L (i>j) 또는 U (i<=j)인 i,j 성분이 구해진다.
def plu_decomp(mat)
  rows, cols = matrix_size(mat)
  # pivot table을 준비하여,
  # pivot 된 행렬의 각 행이 원래 행렬의 모든 행에 대응하고 있는지를 기록한다.
  # mat [i, j]에 직접 접근은 피하고 반드시 함수 p_ref (값 참조) p_set (값 변경)를 통해 lu_decomp 코드를 유용 할 수 있다.
  # "pivot 된 행렬"에 접속하여,
  # lu_decomp의 코드를 준비할 수 있다.
  p = make_vector(rows)
  for i in 1..rows
    p[i] = i  # pivot table의 초기화. 초기값은 "i행은 i"
  end
  # 행수(rows)와 열수(cols)에서 짧은 쪽을 s로 둔다.
  if (rows < cols)
    s = rows
  else
    s = cols
  end
  # 여기부터가 핵심
  for k in 1..s
    # 먼저 pivoting을 해두고
    p_update(mat, k, rows, p)
    # 여기서부터는, lu_decomp을 이렇게 대체하면
    #   mat[i,j] → p_ref(mat, i, j, p)
    #   mat[i,j] = y → p_set(mat, i, j, p, y)
    # 【아】 U의 제 k 행은, 이 단계에서 잔차 자체 → 아무것도 하지 않아도 된다
    # 【이】 L의 제 k 행을 계산
    x = 1.0 / p_ref(mat, k, k, p)
    for i in (k+1)..rows
      y = p_ref(mat, i, k, p) * x
      p_set(mat, i, k, p, y)
    end
    # 【우】 잔차를 갱신
    for i in (k+1)..rows
      x = p_ref(mat, i, k, p)
      for j in (k+1)..cols
        y = p_ref(mat, i, j, p) - x * p_ref(mat, k, j, p)
        p_set(mat, i, j, p, y)
      end
    end
  end
  # pivot table를 반환값으로 한다
  return(p)
end

# pivoting을 시행한다.
# 구체적으로는 k 열 번째 처리되지 않은 부분 중 절대값이 가장 큰 성분을 k 번째 줄로 가져온다.
def p_update(mat, k, rows, p)
  # 후보 (k번째 열의 미처리 부분) 중에서 챔피언(절대 값이 가장 큰 성분)을 찾는다.
  max_val = -777  # 최약의 초대 챔피언. 누구한테도 진다.
  max_index = 0
  for i in k..rows
    x = abs(p_ref(mat, i, k, p))
    if (x > max_val)  # 챔피언을 쓰러 뜨리면
      max_val = x
      max_index = i
    end
  end
  # 현재 행 (k)와 챔피언 행 (max_index)를 교체
  pk = p[k]
  p[k] = p[max_index]
  p[max_index] = pk
end

# pivot된 행렬의 (i,j) 성분값을 돌려준다.
def p_ref(mat, i, j, p)
  return(mat[p[i], j])
end

# pivoting된 행렬의 (i,j) 성분값을 val로 변경
def p_set(mat, i, j, p, val)
  mat[p[i], j] = val
end

# ▼절대값(을 함수기법으로 쓸 수 있도록)
def abs(x)
  return(x.abs)
end

# LU 분해의 결과를 2개의 행렬 L, U로 분할
def plu_split(lu, p)
  rows, cols = matrix_size(lu)
  # 행수(rows)와 열수(cols)에서 짧은 쪽을 s로 둔다.
  if (rows < cols)
    r = rows
  else
    r = cols
  end
  # L은 rows×r, R은 r×cols
  lmat = make_matrix(rows, r)
  umat = make_matrix(r, cols)
  # L을 구한다
  for i in 1..rows
    for j in 1..r
      if (i > j)
        x = p_ref(lu, i, j, p)
      elsif (i == j)  # else if
        x = 1
      else
        x = 0
      end
      lmat[i,j] = x
    end
  end
  # R를 구한다
  for i in 1..r
    for j in 1..cols
      if (i > j)
        x = 0
      else
        x = p_ref(lu, i, j, p)
      end
      umat[i,j] = x
    end
  end
  return [lmat, umat]  # lmat와 umat의 쌍을 반환
end

### 예

if (matrix_test('plu'))
  a = matrix([[2,6,4], [5,7,9]])
  c = matrix_copy(a)
  p = plu_decomp(c)
  l, u = plu_split(c, p)
  puts('A, L, U, and pivot table')
  mp(a)
  mp(l)
  mp(u)
  vp(p)
  puts('L U')
  mp(l * u)
end

#########################################################
# ▼동작 확인
# matrix.rb과 결과를 비교하여 확인.
# 여기서부터는 읽지 않아도 상관없습니다 (봉인 해제)

if ($c)
  require 'matrix'
  $eps = 1e-10
  class MyVector
    def to_a
     @a
    end
  end
  class MyMatrix
    def to_a
     @a
    end
  end
  def rmat(a)
    Matrix.rows a
  end
  def to_array_or_number(x)
    [Array, Matrix, Vector, MyVector, MyMatrix].find{|c| x.is_a? c} ? x.to_a : x
  end
  def aeq?(x, y)
    x = to_array_or_number x
    y = to_array_or_number y
    if x.is_a? Numeric
      y.is_a? Numeric and (x - y).abs < $eps
    elsif x.is_a? Array
      y.is_a? Array and
        x.size == y.size and
        not (0 ... x.size).map{|i| aeq? x[i], y[i]}.member? false
    else
      raise 'Bad type.'
    end
  end
  def rand_ary1(n)
    (1..n).map{|i| rand - 0.5}
  end
  def rand_ary2(m,n)
    (1..m).map{|i| rand_ary1 n}
  end
  def check_matmul(l,m,n)
    a = rand_ary2 l, m
    b = rand_ary2 m, n
    aeq? rmat(a) * rmat(b), matrix(a) * matrix(b)
  end
  def check_det(n)
    a = rand_ary2 n, n
    aeq? rmat(a).det, det(matrix(a))
  end
  def check_inv(n)
    a = rand_ary2 n, n
    aeq? rmat(a).inv, inv(matrix(a))
  end
  def check(label, repeat, proc)
    (1..repeat).each{|t| raise "#{label}" if !proc.call}
    puts "#{label}: ok"
  end
  [
    ['matmul', 100, lambda{check_matmul 6,5,4}],
    ['det', 100, lambda{check_det 7}],
    ['inv', 100, lambda{check_det 7}],
    ['aeq?', 1,
      lambda{
        ![
          # all pairs must be !aeq?
          [3, 3.14],
          [Vector[3], 3],
          [3, vector([3])],
          [Vector[1,2,3], vector([1,2,3,4])],
          [Vector[1,2,3,4], vector([1,2,3])],
          [Vector[1.1,2.2,3.3], vector([1.1,2.2000001,3.3])],
          [rmat([[1,2,3], [4,5,6]]), matrix([[1,2,3], [4.0000001,5,6]])],
        ].map{|a| !aeq?(*a)}.member? false}],
    ['----------- All Tests -----------', 1, lambda{true}],
    ['This must fail. OK if you see an error.', 1, lambda{aeq? 7.77, 7.76}],
  ].each{|a| check *a}
end
