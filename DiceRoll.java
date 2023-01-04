class DiceRoll {

    private static final int M = 1000000007;

    private static class Row {

        int[] arr;
        int sum, idx;

        private Row(int rollMax) {
            arr = new int[rollMax];
            arr[0] = 1;
            sum = 1;
            idx = 1;
        }

        private void update(int totalSum) {
            idx %= arr.length;
            int newSum = Math.floorMod(totalSum - arr[idx], M);
            arr[idx] = Math.floorMod(totalSum - sum, M);
            sum = newSum;
            idx++;
        }
    }

    private static class Calc {

        Row[] rows = new Row[6];

        private Calc(int[] rollMax) {
            for (int i = 0; i < 6; i++) {
                rows[i] = new Row(rollMax[i]);
            }
        }

        private void update() {
            int sum = sum();
            for (Row row : rows) {
                row.update(sum);
            }
        }

        private int sum() {
            int l0 = (rows[0].sum + rows[1].sum) % M;
            int l1 = (rows[2].sum + rows[3].sum) % M;
            int l2 = (rows[4].sum + rows[5].sum) % M;
            return ((l0 + l1) % M + l2) % M;
        }

    }

    public int dieSimulator(int n, int[] rollMax) {
        Calc c = new Calc(rollMax);
        for (int i = 1; i < n; i++) {
            c.update();
        }
        return c.sum();
    }

}
